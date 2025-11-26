# Micdrop

Extensible framework/library to migrate data from source to another using a more declarative interface. It is primarily intended for use in:

* Import scripts
* Export scripts
* Cross-application data migrations

At its core, the library's operation is quite simple: loop over the rows of the source data, perform some transformations, and output the transformed data to the sink.

```ruby
source = CSV.read("data_source.csv", headers:true)
sink = Micdrop::Ext::Sequel::InsertSink.new DB[:destination_table]

migrate source, sink do
    take "Name", put: :name
    take "Birth Date" do
        parse_date "%m/%d/%y"
        format_date "%Y-%d-%m"
        put :dob
    end
    take "Deceased?" do
        parse_boolean
        default false
        put :is_deceased
    end
end
```

> **Note:**
> 
> This is a re-implementation in Ruby of my [previous attempt](https://github.com/dmjohnsson23/micdrop) at this concept in Python. Ruby provides a far superior syntax for this concept than Python. The Python version, however, it far more feature-complete, whereas this version is still in early development.

## Terminology

* Source: A source of data at the beginning of a pipeline; a sequence of multiple Records.
* Sink: The final destination in which Records are to be stored after their transformations.
* Record: A single record in a Source. (For example, a database row.)
* Item: An sub-component or a record. (Such as a database column. Items may also be Records themselves if the parent record represents structured data such as JSON.)
* Take: Extract a single Item from a Record or Collector
* Put: Deposit a single item into a Collector
* Collector: Similar to a Record, but intended to be filled by the migration rather than coming from the source. (A single Collector exists by default, which will be pushed to the Sink. However, you can also use manually-created Collectors as Items to build up hierarchical structures.)

For any curious, the library name itself is partially an abbreviation of the words, "Migrate, Import, and Convert".

## Usage

Before we can begin a migration, we need a source and a sink.

Essentially, any Ruby object which meets the following criteria can be used as a source:

* The object responds to `:each`, `:each_with_index`, and/or `:each_pair` (so, any `Enumerator` works)
* The items yielded by `:each` and friends respond to `:[]`

A sink is similar, but has a single criteria: it must respond to `:<<`.

By default, the `:<<` method of the sink will receive a hash. However, if another object is needed, 
the sink may optionally implement `:make_collector` to return another object instead. The collector 
must respond to `:[]=` but otherwise may be any object you wish.

### Simple Migrations

Let's begin with the simplest possible migration:

```ruby
# Many objects can be used as sources. While dedicated source classes exist for more complex
# use-cases, even a simple array of hashes can be used as a source.
source = [
    {a:1, b:2},
    {a:3, b:4},
    {a:5, b:6},
]

# Likewise, a simple array can also be used as a sink, though special classes exist for more 
# complex use-cases.
sink = []

migrate source, sink do # This block is executed for every record in the source
    # If no conversion is needed, you can simply Take items and Put them in the appropriate place
    take :a, put: "A"
    take :b, put: "B"
end

# `sink` now looks like this:
[
    {"A"=>1, "B"=>2},
    {"A"=>3, "B"=>4},
    {"A"=>5, "B"=>6},
]
```

Or course, data rarely maps so cleanly in the real world; conversion is usually needed. Adding a block to the Take allows you to specify transforms:

```ruby
source = [
    {a:"Yes", b:"08/07/22", c:"Stuff"},
    {a:"Yes", b:"24/04/24", c:"Things"},
    {a:"No", b:"11/12/21", c:nil},
]
sink = []

migrate source, sink do
    take :a, put: "A" do
        parse_boolean
    end
    take :b, put: "B" do
        # We"ll parse the date from a string, and then format it in the new format
        parse_date "%m/%d/%y"
        format_date "%Y-%d-%m"
    end
    take :c  do
        default "Whatsit"
        # The Put can optionally be specified in the block body rather than as a method parameter
        put "C"
    end
    # Method chaining is also allowed. The previous block could alternatively have bee written as:
    take(:c).default("Whatsit").put("C")
end

# `sink` now looks like this:
[
    {"A"=>true, "B"=>"2022-07-08", "C"=>"Stuff"},
    {"A"=>true, "B"=>"2024-04-24", "C"=>"Things"},
    {"A"=>false, "B"=>"2021-12-11", "C"=>"Whatsit"},
]
```

Each block acts as a pipeline, with each transform being executed sequentially and modifying the value in-place. Your pipelines can be arbitrarily complex, and even include multiple Puts at different stages of the pipeline.

### Destructuring Data

If your source data is more structured, you can use `scope` and `extract` to navigate the tree:

```ruby
source = [
    {some:{deeply:{nested:{data: "1", stuff: "2"}}, other: "3"}},
    {some:{deeply:{nested:{data: "4", stuff: "5"}}, other: "6"}},
    {some:{deeply:{nested:{data: "7", stuff: "8"}}, other: "9"}},
]
sink = []

migrate source, sink do
    take :some do
        scope do
            # The `scope` method prevents operations in this block from affecting the value in 
            # the outer `take` block. The `extract` method traverses down the tree.
            extract :other
            put :some_other
        end
        scope do
            # `extract` can be used multiple times to go down multiple levels
            extract :deeply
            extract :nested
            # And scopes can be nested
            scope do
                extract :data
                put :some_deeply_nested_data
            end
            scope do
                extract :stuff
                put :some_deeply_nested_stuff
            end
        end
    end
    # If you only need a single item in a deeply nested structure, you can chain all the  methods 
    # directly on the `take` as well
    take(:some).extract(:deeply).extract(:nested).extract(:stuff).put(:some_deeply_nested_stuff)
    # Or even use `take_dig`
    take_dig :some, :deeply, :nested, :stuff, put: :some_deeply_nested_stuff
end
```

### Outputting Structured Data

By default, Micdrop assumes your output data follows a normal row/column structure, rather than containing complex strucutures. Micdrop has some limited suport for building up structure, though more complex tools are in the works for the future.

The `collect_list` method is currently the primary supported way of building up structure. It takes multiple `take`s and allows them to be operated on in a single pipeline:

```ruby
source = [
    {person: 1, home_phone: nil, work_phone: "(354) 756-4796", cell_phone: "(234) 678-7564"},
    {person: 2, home_phone: "(867) 123-9748", work_phone: nil, cell_phone: "(475) 364-8365"},
]
sink = []

migrate source, sink do
    take :person, put: :person_id
    collect_list(take(:home_phone), take(:work_phone), take(:cell_phone)) do
        # Here, the value is a list containing the values of all three `take`s
        # We can remove the nil values from the list
        compact
        # Then join the remaining as a JSON-formatted list
        format_json
        put :phones
    end
end

# `sink` now looks like this:
[
    {person_id: 1, phones: '["(354) 756-4796", "(234) 678-7564"]'},
    {person_id: 2, phones: '["(867) 123-9748", "(475) 364-8365"]'},
]
```

There are several other methods that are useful for operating on collected lists as well, such as `filter`, `map`, `coalesce`, and `map_apply`.

In addition to `collect_list`, there is also `collect_kv` which takes a hash of `take`s as the first argument:

```ruby
migrate source, sink do
    take :person, put: :person_id
    collect_kv({"Home"=>take(:home_phone), "Work"=>take(:work_phone), "Cell"=>take(:cell_phone)}) do
        # Here, the value is a hash containing the values of all three `take`s
    end
end
```

And also `collect_format_string`, which collects multiple items into a format string:


```ruby
migrate source, sink do
    take :person, put: :person_id
    collect_format_string("Home: %s, Work: %s, Cell: %s", take(:home_phone), take(:work_phone), take(:cell_phone)) do
        # Here, the value is a string with the `take`n values inserted
    end
end
```

### Creating Multiple Output Records

For instances where a single source record maps to multiple sink records, there are techniques for outputting multiple records. The first is simply to use `flush`.

```ruby
source = [
    {person: 1, home_phone: "(634) 654-2457", work_phone: "(354) 756-4796", cell_phone: "(234) 678-7564"},
    {person: 2, home_phone: "(867) 123-9748", work_phone: "(234) 534-2667", cell_phone: "(475) 364-8365"},
]
sink = []

migrate source, sink do
    take :person, put: :person_id
    take :home_phone, put: :number
    static "Home", put: :type
    flush # This creates the first record and resets the collector
    # Now we start the second record
    take :person, put: :person_id
    take :work_phone, put: :number
    static "Work", put: :type
    flush 
    # And the third record
    take :person, put: :person_id
    take :cell_phone, put: :number
    static "Cell", put: :type
    # There is an implicit flush at the end of the block, so we don't need an explicit one (though it won't hurt anything)
end

# `sink` now looks like this:
[
    {person_id: 1, number: "(634) 654-2457", type: "Home"},
    {person_id: 1, number: "(354) 756-4796", type: "Work"},
    {person_id: 1, number: "(234) 678-7564", type: "Cell"},
    {person_id: 2, number: "(867) 123-9748", type: "Home"},
    {person_id: 2, number: "(234) 534-2667", type: "Work"},
    {person_id: 2, number: "(475) 364-8365", type: "Cell"},
]
```

`flush` takes an optional `reset` parameter that is true by default. If set to false, the output will still be generated, but the collector will not be reset.

In cases where iteration is desired, `each_subrecord` provides a convenient interface:

```ruby
source = [
    {person: 1, addresses: [{line1: "123 Example St.", city: "Anytown", state: "AL", zip: "12345", role: "Mailing"}]},
    {person: 2, addresses: [{line1: "123 Any Way", city: "Thereabouts", state: "AK", zip: "98765", role: "Home"}, {line1: "PO Box 123", city: "Thereabouts", state: "AK", zip: "98765", role: "Mailing"}]},
]
sink = []

migrate source, sink do
    # Save this so we can `put` it separately in each record
    person_id = take :person
    # Iterate each address, and automatically flush and reset after each
    take(:addresses).each_subrecord flush: true, reset: true do
        person_id.put :person_id
        take :line1, put: :line1
        take :city, put: :city
        take :state, put: :state
        take :zip, put: :zip
        take :role, put: :role
    end
end

# `sink` now looks like this:
[
    {person_id: 1, line1: "123 Example St.", city: "Anytown", state: "AL", zip: "12345", role: "Mailing"},
    {person_id: 2, line1: "123 Any Way", city: "Thereabouts", state: "AK", zip: "98765", role: "Home"},
    {person_id: 2, line1: "PO Box 123", city: "Thereabouts", state: "AK", zip: "98765", role: "Mailing"},
]
```

There may also be cases where multiple sinks are needed, rather than merely multiple records in the same sink. For this use case, it is recommended to simply iterate the same source multiple times, once to each sink.

```ruby
source = [
    {id: 1, first_name: "Alice", last_name: "Anderson", mail_line1: "123 Example St.", mail_city: "Anytown", mail_state: "AL", mail_zip: "12345"},
    {id: 2, first_name: "Bob", last_name: "Benson", mail_line1: "PO Box 123", mail_city: "Thereabouts", mail_state: "AK", mail_zip: "98765"},
]
person_sink = []
address_sink = []

migrate source, person_sink do
    take :id, put: :id
    take :first_name, put: :fname
    take :last_name, put: :lname
end

migrate source, address_sink do
    take :id, put: :person_id
    take :mail_line1, put: :line1
    take :mail_city, put: :city
    take :mail_state, put: :state
    take :mail_zip, put: :zip
    static "Mailing", put: :role
end
```

### Filling the Gaps

If you find yourself writing the same block multiple times, you can instead write it as a proc and apply that to the Takes.

```ruby
source = [
    {a:1, b:2},
    {a:nil, b:4},
    {a:5, b:nil},
]
sink = []

default_0 = proc do
    # This reusable pipeline can be as complex as needed
    default 0
end

migrate source, sink do
    # Both of the following syntaxes are equivilent
    take :a, apply: default_0, put: "A"
    take :b do
        apply default_0
        put "B"
    end
end

# `sink` now looks like this:
[
    {a:1, b:2},
    {a:0, b:4},
    {a:5, b:0},
]
```

Of course, you may need to modify data in ways that are not supported by existing transforms. But, you can just use plain old Ruby to fill the gaps. There are a few ways to do this:

```ruby
source = [
    {a:1, b:2, c:3},
    {a:4, b:5, c:6},
    {a:7, b:8, c:9},
]
sink = []

migrate source, sink do
    # You can pass a proc (or symbol) to the `convert` parameter
    take :a, convert: proc {it + 1}, put: "A"
    # Or you can use a `convert` block
    take :b do
        convert {it * 2}
        put "B"
    end
    # Or you can use the `update` and `value` methods directly in the main item block
    take :c do
        if value % 2
            update "Odd"
        else
            update "Even"
        end
        put "C"
    end
end

# `sink` now looks like this:
[
    {"A"=>2, "B"=>4, "C"=>"Odd"},
    {"A"=>5, "B"=>10, "C"=>"Even"},
    {"A"=>8, "B"=>16, "C"=>"Odd"},
]
```

And transforms are nothing more than standard Ruby methods; there is no magic going on under the hood (other than the normal Ruby magic). So, if you find yourself needing the same pure-Ruby code often, you can just extend `ItemContext` with an additional method, which can then be used as a transform.

```ruby
module Micdrop
    class ItemContext
        def subtract(v)
            # Do whatever you like here; just make sure to save the result to @value
            @value = @value - v
            # Also return `self` to enable method chaining
            self
        end
    end
end

migrate source, sink do
    take :a do
        subtract 1
        put "A"
    end
```


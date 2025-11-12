# Micdrop

Extensible framework/library to migrate data from source to another using a more declarative interface. It is primarilly intended for use in:

* Import scripts
* Export scripts
* Cross-application data migrations

At its core, the library's operation is quite simple: loop over the rows of the source data, perform some transformations, and output the transformed data to the sink.

```ruby
migrate CSV.read('data_source.csv', headers:true), TableInsertSink.new('destination') do
    take 'Name', put: :name
    take 'Birth Date' do
        parse_date '%m/%d/%y'
        format_date '%Y-%d-%m'
        put :dob
    end
    take 'Deceased?' do
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

## Installation

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG` with your gem name right after releasing it to RubyGems.org. Please do not do it earlier due to security reasons. Alternatively, replace this section with instructions to install your gem from git if you don't plan to release to RubyGems.org.

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

## Usage

Before we can begin a migration, we need a source and a sink.

Essensially, any Ruby object which meets the following criteria can be used as a source:

* The object responds to `:each`, `:each_with_index`, and/or `:each_pair` (so, any `Enumerator` works)
* The items yieled by `:each` and friends respond to `:[]`

A sink is similar, but has a single criteria: it must respond to `:<<`.

By default, the `:<<` method of the sink will receive a hash. However, if another object is needed, 
the sink may optionally implement `:make_collector` to return another object instead. The collector 
must respond to `:[]=` but otherwise may be any object you wish.

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
    take :a, put: 'A'
    take :b, put: 'B'
end

# `sink` now looks like this:
[
    {'A'=>1, 'B'=>2},
    {'A'=>3, 'B'=>4},
    {'A'=>5, 'B'=>6},
]
```

Or course, data rarely maps so cleanly in the real world; conversion is usually needed. Adding a block to the Take allows you to specify transforms:

```ruby
source = [
    {a:'Yes', b:'08/07/22', c:'Stuff'},
    {a:'Yes', b:'24/04/24', c:'Things'},
    {a:'No', b:'11/12/21', c:nil},
]
sink = []

migrate source, sink do
    take :a, put: 'A' do
        parse_boolean
    end
    take :b, put: 'B' do
        # We'll parse the date from a string, and then format it in the new format
        parse_date '%m/%d/%y'
        format_date '%Y-%d-%m'
    end
    take :c  do
        default 'Whatsit'
        # The Put can optionally be specified in the block body rather than as a method parameter
        put 'C'
    end
end

# `sink` now looks like this:
[
    {'A'=>true, 'B'=>'2022-07-08', 'C'=>'Stuff'},
    {'A'=>true, 'B'=>'2024-04-24', 'C'=>'Things'},
    {'A'=>false, 'B'=>'2021-12-11', 'C'=>'Whatsit'},
]
```

Each block acts as a pipeline, with each transform being executed sequentially and modifying the value in-place. Your pipelines can be arbitrarilly complex, and even include multiple Puts at different stages of the pipeline.

If you find yourself writing the same block multiple times, you can instead write it as a proc and apply that to the Takes.

```ruby
source = [
    {a:1, b:2},
    {a:nil, b:4},
    {a:5, b:nil},
]
sink = []

migrate source, sink do
    default_0 = proc do
        # This reusable pipline can be as complex as needed
        default 0
    end
    # Both of the following are equivilent
    take :a, apply: default_0, put: 'A'
    take :b do
        apply default_0
        put 'B'
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
    take :a, convert: proc {it + 1}, put: 'A'
    # Or you can use a `convert` block
    take :b do
        convert {it * 2}
        put 'B'
    end
    # Or you can use the `update` and `value` methods directly in the main item block
    # (`value=` is also supported if you prefer)
    take :c do
        if value % 2
            update 'Odd'
        else
            update 'Even'
        end
        put 'C'
    end
end

# `sink` now looks like this:
[
    {'A'=>2, 'B'=>4, 'C'=>'Odd'},
    {'A'=>5, 'B'=>10, 'C'=>'Even'},
    {'A'=>8, 'B'=>16, 'C'=>'Odd'},
]
```

And transforms are nothing more than standard Ruby methods; there is no magic going on under the hood (other than the normal Ruby magic). So, if you find yourself needing the same pure-Ruby code often, you can just extend `ItemContext` with an additional method, which can then be used as a transform.

```ruby
module Micdrop
    class ItemContext
        def subtract(v)
            # Do whatever you like here; just make sure to save the result to @value
            @value = @value - v
        end
    end
end

migrate source, sink do
    take :a do
        subtract 1
        put 'A'
    end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/micdrop.

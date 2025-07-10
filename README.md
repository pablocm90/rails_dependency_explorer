# RailsDependencyExplorer

A Ruby gem for analyzing and visualizing dependencies in Rails applications. Extract class dependencies, method calls, and constant references to understand your Rails application's structure and identify potential issues like circular dependencies.

## Features

- **Dependency Analysis**: Parse Ruby code to extract class dependencies and method calls
- **Rails Component Detection**: Automatically categorize classes as models, controllers, services, or other components
- **Multiple Output Formats**: Export analysis results as DOT graphs, JSON, HTML, CSV, or console output
- **Circular Dependency Detection**: Identify and report circular dependencies in your codebase
- **Dependency Statistics**: Calculate metrics like dependency counts and depth analysis
- **Command Line Interface**: Easy-to-use CLI for analyzing Rails applications

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

### Programmatic API

```ruby
require 'rails_dependency_explorer'

# Analyze a single Ruby file
explorer = RailsDependencyExplorer::Analysis::DependencyExplorer.new
result = explorer.analyze_code(ruby_code)

# Get dependency statistics
puts result.statistics

# Detect circular dependencies
puts result.circular_dependencies

# Categorize Rails components
components = result.rails_components
puts "Models: #{components[:models]}"
puts "Controllers: #{components[:controllers]}"
puts "Services: #{components[:services]}"

# Export to different formats
puts result.to_dot      # DOT graph format
puts result.to_json     # JSON format
puts result.to_html     # HTML format
puts result.to_csv      # CSV format
puts result.to_console  # Console output
```

### Command Line Interface

```bash
# Analyze current directory
rails_dependency_explorer analyze

# Analyze specific directory
rails_dependency_explorer analyze /path/to/rails/app

# Export to specific format
rails_dependency_explorer analyze --format json
rails_dependency_explorer analyze --format dot
rails_dependency_explorer analyze --format html
rails_dependency_explorer analyze --format csv

# Save to file
rails_dependency_explorer analyze --output dependencies.json
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/rails_dependency_explorer.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

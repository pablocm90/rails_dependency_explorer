# RailsDependencyExplorer

A Ruby gem for analyzing and visualizing dependencies in Rails applications. Extract class dependencies, method calls, and constant references to understand your Rails application's structure and identify potential issues like circular dependencies.

## Features

- **Dependency Analysis**: Parse Ruby code to extract class dependencies and method calls
- **Rails Component Detection**: Automatically categorize classes as models, controllers, services, or other components
- **ActiveRecord Relationship Analysis**: Detect and analyze ActiveRecord associations (belongs_to, has_many, has_one, has_and_belongs_to_many)
- **Rails Configuration Tracking**: Track Rails configuration dependencies (Rails.env, Rails.logger, Rails.application.config, ENV variables)
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

# Analyze ActiveRecord relationships
relationships = result.activerecord_relationships
puts "User belongs_to: #{relationships['User'][:belongs_to]}"
puts "User has_many: #{relationships['User'][:has_many]}"
puts "User has_one: #{relationships['User'][:has_one]}"

# Analyze Rails configuration dependencies
config_deps = result.rails_configuration_dependencies
puts "Rails config: #{config_deps['UserService'][:rails_config]}"
puts "Environment vars: #{config_deps['UserService'][:environment_variables]}"

# Export to different formats
puts result.to_dot      # DOT graph format
puts result.to_json     # JSON format
puts result.to_html     # HTML format
puts result.to_csv      # CSV format
puts result.to_console  # Console output

# Rails-aware visualization (shows model relationships instead of ActiveRecord methods)
puts result.to_rails_dot    # DOT format with model relationships
graph = result.to_rails_graph  # Graph structure with model relationships
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

### Visualization Modes

The gem provides two visualization modes:

**Standard Mode**: Shows all dependencies including ActiveRecord method calls
- `result.to_dot` - Shows edges like `User -> ActiveRecord::belongs_to`
- `result.to_graph` - Includes ActiveRecord method nodes

**Rails-Aware Mode**: Shows actual model relationships for cleaner Rails application graphs
- `result.to_rails_dot` - Shows edges like `User -> Account` (actual model relationships)
- `result.to_rails_graph` - Filters out ActiveRecord method nodes, shows target models

The Rails-aware mode is particularly useful for understanding the actual data relationships in your Rails application, while the standard mode shows the complete code dependency picture.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/rails_dependency_explorer.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

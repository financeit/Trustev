# Trustev

An API client library for the [Trustev API][trustev_api].

## Usage

The following config attributes need to be set when using the gem:

```ruby
Trustev.configure do |config|
  config.url = <TRUSTEV API URL>
  config.username = <TRUSTEV API USERNAME>
  config.password = <TRUSTEV API PASSWORD>
  config.solution_set_id = <TRUSTEV API SOLUTION SET ID>
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/financeit/trustev.

## About Financeit

[Financeit] is a fintech startup based in Toronto, Canada and we're [hiring].

[trustev_api]: https://trustev.com/
[financeit]: https://www.financeit.io/
[hiring]: https://www.financeit.io/ca/en/careers

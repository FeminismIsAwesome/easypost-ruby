# EasyPost Ruby Client Library

[![Build Status](https://github.com/EasyPost/easypost-ruby/workflows/CI/badge.svg)](https://github.com/EasyPost/easypost-ruby/actions?query=workflow%3ACI)
[![Gem Version](https://badge.fury.io/rb/easypost.svg)](https://badge.fury.io/rb/easypost)


EasyPost is a simple shipping API. You can sign up for an account at https://easypost.com.

## Installation

Install the gem:

```bash
gem install easypost
```

Import the EasyPost client in your application:

```ruby
require 'easypost'
```

## Example

```ruby
require 'easypost'
EasyPost.api_key = 'API_KEY'

to_address = EasyPost::Address.create(
  :name => 'Dr. Steve Brule',
  :street1 => '179 N Harbor Dr',
  :city => 'Redondo Beach',
  :state => 'CA',
  :zip => '90277',
  :country => 'US',
  :phone => '310-808-5243'
)

from_address = EasyPost::Address.create(
  :company => 'EasyPost',
  :street1 => '118 2nd Street',
  :street2 => '4th Floor',
  :city => 'San Francisco',
  :state => 'CA',
  :zip => '94105',
  :phone => '415-456-7890'
)

parcel = EasyPost::Parcel.create(
  :width => 15.2,
  :length => 18,
  :height => 9.5,
  :weight => 35.1
)

customs_item = EasyPost::CustomsItem.create(
  :description => 'EasyPost T-shirts',
  :quantity => 2,
  :value => 23.56,
  :weight => 33,
  :origin_country => 'us',
  :hs_tariff_number => 123456
)

customs_info = EasyPost::CustomsInfo.create(
  :integrated_form_type => 'form_2976',
  :customs_certify => true,
  :customs_signer => 'Dr. Pepper',
  :contents_type => 'gift',
  :contents_explanation => '', # only required when contents_type => 'other'
  :eel_pfc => 'NOEEI 30.37(a)',
  :non_delivery_option => 'abandon',
  :restriction_type => 'none',
  :restriction_comments => '',
  :customs_items => [customs_item]
)

shipment = EasyPost::Shipment.create(
  :to_address => to_address,
  :from_address => from_address,
  :parcel => parcel,
  :customs_info => customs_info
)

shipment.buy(
  :rate => shipment.lowest_rate
)

shipment.insure(amount: 100)

puts shipment.insurance

puts shipment.postage_label.label_url
```

## Documentation

Up-to-date documentation at: https://easypost.com/docs

## Development

```bash
# Run tests (coverage is generated on a successful test suite run)
EASYPOST_TEST_API_KEY=123... EASYPOST_PROD_API_KEY=123... bundle exec rspec
```

## Custom connections

Set `EasyPost.default_connection` to an object that responds to `call(method, path, api_key = nil, body = nil)`

### Faraday

```ruby
require 'faraday'
require 'faraday/response/logger'
require 'logger'

EasyPost.default_connection = lambda do |method, path, api_key = nil, body = nil|
  Faraday
    .new(url: EasyPost.api_base, headers: EasyPost.default_headers) { |builder|
      builder.use Faraday::Response::Logger, Logger.new(STDOUT), {bodies: true, headers: true}
      builder.adapter :net_http
    }
    .public_send(method, path) { |request|
      request.headers['Authorization'] = EasyPost.authorization(api_key)
      request.body = JSON.dump(EasyPost::Util.objects_to_ids(body)) if body
    }.yield_self { |response|
      EasyPost.parse_response(
        status: response.status,
        body: response.body,
        json: response.headers['Content-Type'].start_with?('application/json'),
      )
    }
end
```

### Typhoeus

```ruby
require 'typhoeus'

EasyPost.default_connection = lambda do |method, path, api_key = nil, body = nil|
  Typhoeus.public_send(
    method,
    File.join(EasyPost.api_base, path),
    headers: EasyPost.default_headers.merge('Authorization' => EasyPost.authorization(api_key)),
    body: body.nil? ? nil : JSON.dump(EasyPost::Util.objects_to_ids(body)),
  ).yield_self { |response|
    EasyPost.parse_response(
      status: response.code,
      body: response.body,
      json: response.headers['Content-Type'].start_with?('application/json'),
    )
  }
end
```

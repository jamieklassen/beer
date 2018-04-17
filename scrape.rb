require 'selenium-webdriver'
require 'capybara'

# Configurations
Capybara.register_driver :selenium do |app|  
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end
Capybara.javascript_driver = :chrome
Capybara.configure do |config|  
  config.default_max_wait_time = 10 # seconds
  config.default_driver = :selenium
end

def browser
  Capybara.current_session
end

def strong_beers
  top_url = 'http://www.thebeerstore.ca/beers/search/beer_style--Strong'
  browser.visit(top_url)
  links = browser.find_all 'a.brand-link.teaser'
  urls = links.map { |l| l['href'] }
end

class Beer
  attr_reader :name, :abv, :price_rows

  def initialize(url)
    browser.visit(url)
    @name = browser.find('.page-title').text
    @abv = begin
      defs = browser.find_all 'div.brand-info-inner > dl > dd'
      defs.last.text.to_f
    end
    @price_rows = browser.find_all('div.brand-pricing-wrapper tbody tr').
      map { |n| PriceRow.new(n, self) }
  end
end

class PriceRow
  attr_reader :beer, :price, :count, :unit_volume
  def initialize(node, beer)
    @beer = beer
    size = node.find('.size').text
    @count = size.split('×').first.to_i
    @unit_volume = size.split('×').last[/\d+/].to_i
    @price = node.find('.price').text.gsub(/[^\d\.]/, '').to_f
  end

  def kars
    @price / (@count * @unit_volume * @beer.abv)
  end

  def to_s
    "#{@beer.name} - #{@count} × #{@unit_volume} ml"
  end
end

def all_prices
  strong_beers.flat_map { |url| Beer.new(url).price_rows }
end

def best_value
  # bavaria 8.6 is actually only 7.9 ABV
  # today I only have 16 bucks for beer
  all_prices.reject { |pr| pr.price > 16 || pr.beer.name == 'bavaria 8.6' }.min_by(&:kars)
end

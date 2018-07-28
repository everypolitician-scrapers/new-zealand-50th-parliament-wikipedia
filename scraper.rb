#!/bin/env ruby
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'
require 'wikidata_ids_decorator'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class MembersPage < Scraped::HTML
  decorator WikidataIdsDecorator::Links

  field :members do
    members_tables.xpath('.//tr[td[2]]').map { |tr| fragment(tr => MemberRow).to_h }
  end

  private

  def members_tables
    noko.xpath('//table[.//th[contains(.,"Term in office")]]')
  end
end

class MemberRow < Scraped::HTML
  field :name do
    tds[1].css('a').map(&:text).map(&:tidy).first
  end

  field :id do
    tds[1].css('a/@wikidata').map(&:text).first
  end

  field :area do
    tds[1].css('a').map(&:text).map(&:tidy).first
  end

  field :area_id do
    tds[2].css('a/@wikidata').map(&:text).first
  end

  field :party do
    party_header.text.sub(/\s\(.*\)/,'')
  end

  # This is currently always the first link after the header (though
  # presumably not always going to be so!)
  field :party_wikidata do
    next_para = party_header.xpath('following::p[1]')
    next_para.css('a/@wikidata').map(&:text).first
  end

  private

  def tds
    noko.css('td')
  end

  def party_header
    noko.xpath('preceding::h3/span[@class="mw-headline"]').last
  end
end

url = 'https://en.wikipedia.org/wiki/50th_New_Zealand_Parliament'
Scraped::Scraper.new(url => MembersPage).store(:members, index: %i[name party])

[![CircleCI](https://circleci.com/gh/EmCousin/pkp/tree/master.svg?style=svg)](https://circleci.com/gh/EmCousin/pkp/tree/master)

# README

## Description

Back-Office interface for Parkour Paris

## Prerequisites
* Ruby 2.6.3 or later
* PostgreSQL 9.4 or later
* Yarn
* Foreman

## Installation
* Clone with Git
* run `gem install bundler && bundle install`
* run `rake db:create`
* run `rake db:migrate`
* run `rake db:seed`
* Run `yarn install`

## Booting
* Run `foreman start -f Procfile.dev`

## Running tests
* Run `rspec`

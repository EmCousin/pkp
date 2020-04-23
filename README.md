[![CircleCI](https://circleci.com/gh/EmCousin/pkp/tree/master.svg?style=svg)](https://circleci.com/gh/EmCousin/pkp/tree/master)

# README

## Description

Back-Office interface for Parkour Paris

## Prerequisites
* [Ruby](https://www.ruby-lang.org/en/documentation/installation/) 2.6.3 or later
* [Node](https://nodejs.org/en/download/) 10 or later
* [PostgreSQL](https://www.postgresql.org/download/) 9.4 or later
* [Redis](https://redis.io/topics/quickstart)
* [Yarn](https://classic.yarnpkg.com/en/docs/install/)
* [Foreman](https://github.com/ddollar/foreman)

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

[![CircleCI](https://circleci.com/gh/EmCousin/pkp/tree/master.svg?style=shield)](https://circleci.com/gh/EmCousin/pkp/tree/master)
[![GitHub issues](https://img.shields.io/github/issues/EmCousin/pkp)](https://github.com/EmCousin/pkp/issues)
[![Maintainability](https://api.codeclimate.com/v1/badges/d11f43afa6788ac81980/maintainability)](https://codeclimate.com/github/EmCousin/pkp/maintainability)

# README

## Description

Back-Office interface for [Parkour Paris](https://inscriptions.parkourparis.fr)

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

# Hledger-Forecast

![Tests](https://github.com/olimorris/hledger-forecast/workflows/ci/badge.svg)

> **Warning**: This is still in the early stages of development and the API is likely to change

Uses a `YAML` file to generate monthly, quarterly, yearly and one-off transactions for better forecasting in [Hledger](https://github.com/simonmichael/hledger).

While Hledger provides support for [forecasting](https://hledger.org/1.29/hledger.html#forecasting) using periodic transactions, these are computed virtually at runtime. The goal of this gem is to offer an alternative approach that enables easy reconciliation to specific figures and accommodates common financial factors, such as inflation.

## :package: Installation

Assuming you have Ruby and [Rubygems](http://rubygems.org/pages/download) installed on your system, simply run:

    gem install --user hledger-forecast

## :rocket: Usage

Firstly, setup a `yml` file which will contain the transactions you'd like


## Rationale



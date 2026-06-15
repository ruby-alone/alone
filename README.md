# Alone

![Logo](https://ruby-alone.org/images/TopLogo.png)

## Overview

Alone is Application Framework for Embedded Systems.

## Requirement

* Ruby 2.7 or later.

## Usage

A "Hello World" program using CGI.

__main.rb__
```ruby
require 'al_template'

class HelloController < AlController
  def action_index()
    @my_message = "Hello world."
    AlTemplate.run("./index.rhtml")
  end
end
```

__index.rhtml__
```rhtml
<%= header_section %>
  <title>Test</title>

<%= body_section %>
  <p><%=h @my_message %></p>

<%= footer_section %>
```

## Features

__CGI module__

* A web application framework using CGI protocol.

__Graph module__

* A feature to display charts such as line and bar graphs.

__Database module__

* A wrapper layer for relational databases (RDB).

__Worker module__

* A framework for developing background daemon services.

## Reference

Web page: [https://www.ruby-alone.org](https://www.ruby-alone.org)
Documents: [https://www.ruby-alone.org/doc/](https://www.ruby-alone.org/doc/)


## Licence

This software is distributed under BSD license.

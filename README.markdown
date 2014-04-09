Redmine Messenger
=================

Plugin to allow users to communicate with Redmine via Instant Messenger.

## Instalation

Install Xmpp4r library.

    $ gem install xmpp4r

Download the sources and put them to your vendor/plugins folder.

    $ cd {REDMINE_ROOT}
    $ git clone git://github.com/mszczytowski/redmine_messenger.git vendor/plugins/redmine_messenger

Copy default messenger.yml to your config folder.

    $ cp vendor/plugins/redmine_messenger/config/messenger.yml config/

Create jabber account for Redmine user and set its configuration in messenger.yml.

    $ vim config/messenger.yml

Migrate database.

    $ rake db:migrate_plugins

Run Redmine and have a fun!

## Translations

- en by myself
- es by smlghst
- ru by akrus
- pl by myself
- de by Michael Jahn
- pt-BR by Diego Oliveira

Thanks for contribution.

## Changelog

### 0.0.9

- new translations (de)

### 0.0.8

- bug fixes (#1, #2)

## Registration

Login to your Redmine. Go to page http://your\_redmine\_domain/user\_messenger and fill Messenger ID field with your jabber id. Click save. You will receive verification code.

Add Redmine jabber account as your contact and send him your verification code. You should receive confirmation.

Type 'help' and read what you can do with it.

## Help

All user related help is on page http://your\_redmine\_domain/user\_messenger.

## Features

* timers
* logging times
* searching for issues
* details of issue
* timer status with logged time statistics
* commenting issues
* pausing/resuming timer when user become away/visible (configurable)
* changing status of issue to 'in progress' while starting timer (configurable)
* changing status of issue to 'finished' while finishing timer with ratio equalt to 100 (configurable)
* assigning issues
* notifications (configurable)

## Extending

To extend functionality create file app/messenger/NAME\_messenger.rb. See app/messenger/issues\_messenger.rb for usage example.

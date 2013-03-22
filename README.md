# Pinch

Pinch is a real-time crisis management app. Its designed to help bring structure and organization to the chaos of a major outage or incident. This tools is also very handy when doing a review later and going on exactly what happened.

It does this by building a real-time timeline of the incident and creates small task list of things to fix and allows individuals to take ownership of them.

Pinch has a fully restful api so you can push/pull data from ANY source.


## How to get setup
Pinch is designed to operate on Heroku, so be sure to setup an accout with them and familarize yourself with their service.

1. Install bundle: `gem install bundle`
2. Install needed gems: `bundle install`
3. Get a [Redis To Go](http://redistogo.com) instance
4. Create a `.env` file with your redis url:

        echo "REDISTOGO_URL=redis://user:password@foo.redistogo.com:<port>/" > .env
5. Get a [MongoHQ](http://mongohq.com) account
6. Add it to your `.env` file with your mongo url

       echo "MONGOHQ_URL=mongodb://user:password@linus.mongohq.com:<port>/pinch" > .env
7. Add session secret to your env
       echo "SESSION_SECRET=this is my session secret phrase" > .env
8. Start the server:
    * if you have the [heroku toolbelt](https://toolbelt.heroku.com/) installed
      use foreman: `foreman start`
    * otherwise, source your `.env` and run manually:

            source .env
            bundle exec ruby pinch.rb -p 5000

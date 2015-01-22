# Referrers

by [Matt Gemmell](http://mattgemmell.com/)


## What is it?

It's a Ruby script that processes Apache access logs, and spits out a list of referrers (sites that linked to your site).


## What are its requirements?

Just Ruby itself.


## What does it do?

It reads Apache access logs, and generates a report file showing any referring URLs. They're not broken down by frequency, destination page, or anything. This is strictly for casual vanity purposes.

Here's some interesting stuff:

- It uses two external configuration files: one for custom template tags (more about that in a moment), and one for URLs you want to exclude from the report.

- The exclusions file is just a list of URLs, one per line. You can use regular expressions, if you like. You probably should.

- The report is generated from a template, which has placeholder tags in it. There's a default HTML template (and accompanying CSS) file included, but you can use whatever you want.

- You can specify other configuration, template and exclusions files on the command line, so you can customise the output whenever necessary. Maybe you sometimes want CSV instead of HTML, or some other funky thing.

- You can also specify the output filename, and the input filename pattern on the command line. The input one is a shell glob pattern, as you'd expect.

- There are a handful of template tags that the script already knows about (see the example template for those), but you can also add any others you might find useful. They go in the configuration file, which is a YAML document. See the sample one.

That's about it.


## How do I use it?

Just put your access logs in the same directory (by default, it looks for files with names beginning "access.log"), and then do `ruby referrers.rb`.

You can use the `-h` switch to learn about a few useful options.

While the script runs, you'll see some information in the terminal, telling you what it's doing. Like you care.

You'll get a report in the same directory, called "report.html" by default. The list of referrers will be in roughly reverse chronological order (newest first), and won't include any duplicates.

You can customise the script's behaviour via the configuration file, command line options, exclusions file and template file. You shouldn't need to change anything in the script itself. Take a look at all the included sample files to see how it works.


## What _doesn't_ it do?

That thing you were hoping it did. Error checking. Any kind of counting of the most popular referrers. And anything I've not explicitly said that it _does_ do.


## Should I run it on my server?

Nope. I run it on my local machine, and so should you.


## Who made it?

Matt Gemmell (that's me).

- My website is at [mattgemmell.com](http://mattgemmell.com)

- I'm on Twitter as [@mattgemmell](http://twitter.com/mattgemmell)

- This code is on github at [github.com/mattgemmell/Referrers](http://github.com/mattgemmell/Referrers)


## What license is the code released under?

Creative Commons [Attribution-Sharealike](http://creativecommons.org/licenses/by-sa/4.0/).


## Why did you make this?

I know: there are already a hundred log-analysers out there, every one of them with far more features than this. I personally just use Google Analytics for most purposes.

But, Analytics doesn't have a great referrers view, and that's what I'm most interested in. I like to know who's linking to me; I read my referrers while I drink my coffee in the morning. I am egocentric and/or insecure.

I didn't find anything suitably simple yet customisable, so I made this.


## The code is horrible

Probably. It's just for my personal use. I'm not a developer or anything.

So's your face.


## Can you provide support?

Nope. If you find a bug, please fix it and submit a pull request via github.


## I have a feature request

Shh.


## How can I thank you?

Good one.

Hypothetically, you can:

- [Support my writing](https://www.patreon.com/mattgemmell).

- Check out [my Amazon wishlist](http://www.amazon.co.uk/registry/wishlist/1BGIQ6Z8GT06F).

- Say thanks [on Twitter](http://twitter.com/mattgemmell), I suppose.


## I have another question

Bye!

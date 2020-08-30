# That One Feed

That One Feed is a super simple app designed to address some downsides to the
main Feedly web interface. There are three main differences: content
negotiation, content splitting, and content sizing.

If you subscribe to a photography blog, the photos are the point of the posts.
Most will have textual captions, but usually of minimal size. That One Feed
recognizes this and moves the textual content to an unobtrusive caption in the
bottom right corner where it's out of your way, and more importantly, makes the
photo display full screen. Even better, if the photos are hosted using certain
well-known services, it'll automatically go find a higher-resolution image and
display that to you instead.

Similarly, it's not uncommon for posts to contain multiple photos, and That
One Feed will split them up so you can look at each photo individually.

Of course, not all posts are so visually-focused. Entries with a large textual
component are displayed as-is, with any visual components inline. Like Feedly,
silly little stuff (e.g., links to share on social media sites) is hidden from
view. Unlike Feedly, inline visual components are scaled to maximize their
impact within the flow of the entry.

## Get In Touch

If you want to get in touch, drop me a line at thatonefeed@barneyb.com, or even
stop by my house for a drink. I have a wide selection of whisk(e)y from the US,
Canada, Ireland, Scotland, and Japan to share over interesting conversation.

## Internals

The front end is constructed using AngularJS, a lightweight JavaScript
framework constructing for rich applications.

The server side is nothing more than a thin proxy to the Feedly Cloud, running
Railo. There is no database; all storage happens directly in the Feedly Cloud.

The entire application's lifecycle is managed via Grunt with the help of Node,
NPM, and a bunch of plugins.

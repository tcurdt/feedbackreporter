When writing desktop applications you are dealing with a huge amount of
different installations. Tracking down a bug requires to get detailed
information on what happened on the user's computer. But most likely you don't
want to bother the users with how to make this information available to you.

I wasn't really satisfied with the frameworks available so I came up with one
that suits my needs. Hopefully it will also suit yours.

For information on how to integrate the FeedbackReporter Framework please see
the [screencast][1] and the [documentation][2].

Suggestions, bug reports and fixes are much welcome. The source code is
available through git at

    git clone git://github.com/tcurdt/feedbackreporter.git

or via [web interface][3]

Enjoy!


Credits:

 * Fraser Speirs, Multipart/Form construction, BSD License
 * Jens Alfke, Exception handling and callstack, BSD License
 * Torsten Curdt, initial codebase, ASL2.0 License

any more contributors sending patches. Thanks!

[1]: http://vafer.org/projects/feedbackreporter/screencasts/Integrating%20with%20FeedbackReporter.mov
[2]: https://github.com/tcurdt/feedbackreporter/blob/master/Documentation/Integration.md
[3]: http://github.com/tcurdt/feedbackreporter/tree/master
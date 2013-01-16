## Version 1.3.1, unreleased
* [ADD] Added Spanish translation. Thanks to Emilio Perez.
* [ADD] Added targetUrlForFeedbackReport to delegate protocol. Thanks to Rick Fillion.
* [FIX] Don't cache server response. Thanks to Rick Fillion.
* [FIX] PLIST_KEY_LOGHOURS should come from the info plist. Thanks to Rico.
* [CHG] Link against Foundation and 10.4 compatibility. Thanks to Linas Valiukas.


## Version 1.3.0, released 18.06.2010

New localizations. New options. Many little fixes. Better CPU detection.
Garbage Collection ready. Ready for inclusion into plugins.

* [FIX] Use @loader_path instead of @executable_path.
* [FIX] Fixed a missing boundary in POSTs.
* [FIX] Catch exceptions also outside of the main thread.
* [FIX] Improved CPU detection.
* [ADD] Changed FRFeedbackReporterDelegate to a real @protocol.
* [ADD] Added support for Garbage Collection.
* [ADD] Added anonymizePreferencesForFeedbackReport delegate method to anonymize logs.
* [ADD] Added option to restrict the log size (FRFeedbackReporter.maxConsoleLogSize).
* [ADD] Added option to opt-out from sending details (FRFeedbackReporter.sendDetailsIsOptional).
* [ADD] Added Armenian translation. Thanks to Gevorg Hakobyan (www.gevorghakobyan.uni.cc).
* [ADD] Added French translation. Thanks to Gevorg Hakobyan (www.gevorghakobyan.uni.cc) and Sylvain.
* [ADD] Added Italian translation. Thanks to Andrea.


## Version 1.2.0, released 29.09.2009

New UI layout, Dropped support for Tiger, Updated for Snow Leopard

* [DEL] Dropped support for Tiger.
* [ADD] Added support for Snow Leopard. Build now also includes 64-bit architecture.
* [ADD] Added Russion translation. Thanks to Максим Буринов
* [CHG] Changed the UI layout to be a more Mac-like. Thanks to Philipp Mayerhofer.


## Version 1.1.4, released 04.07.2009

Asynchronous gathering of system information. Shows all email addresses. Fixed some bugs/crashes.

* [FIX] Fixed a syntax error in the php server script.
* [FIX] Properly synchronize dialog composition.
* [FIX] Only catch the first exception.
* [CHG] Show all email addresses from addressbook.
* [ADD] Asynchronous gathering of system information.
* [ADD] Added Mantis integration.


## Version 1.1.3, released 30.04.2009

Fixex some reported crashes, improved CPU detection, added the option to use
addressbook email instead of anonymous

* [FIX] Improperly retained log information caused crashes.
* [FIX] Not checking for ASL results caused crashes.
* [FIX] Read-only tableview.
* [CHG] More detailed CPU detection on 10.5+.
* [ADD] Preset email address from addressbook if key FRFeedbackReporter.addressbookEmail is present.
* [ADD] Send along the type of the report (feedback/exception/crash).
* [ADD] Include full Xcode project into release.


## Version 1.1.2, released 12.02.2009

Prefixed the internal classes and some small fixes. Console log time window
now configurable.

* [CHG] Prefixed also the internal classes.
* [CHG] Less logging.
* [FIX] Escape the feedback URL.
* [FIX] Fixed spelling mistake in English localization.
* [FIX] Retain the tabs properly.
* [FIX] Fixed the app example to call framework in applicationDidFinishLaunching.
* [ADD] Made the log time window to send configurable.


## Version 1.1.0, released 09.08.2008

This is a release with some major changes. A non-modal window makes it more
user friendly. The UI has been refined a bit. Deprecated API methods have been
removed and a German localization has been added. Please contact me for
localization in other languages.

* [CHG] Uses a non-modal window now!
* [CHG] Different messages depending on how invoked.
* [CHG] Only send the latest crash report.
* [CHG] Only show relevant tabs.
* [CHG] Restrict the ASL log information.
* [CHG] Show system profile in table.
* [CHG] Use scrollers and don't break the lines.
* [CHG] Server script can now auto-add new project.
* [CHG] FRFeedbackReport should now be used as a Singleton.
* [DEL] Removed deprecated methods.
* [DEL] Removed a dedicated user attribute.
* [ADD] Now supports delegation. Custom values can be send along.
* [ADD] German localization.


## Version 1.0.1, released 01.06.2008

A critical bug fix release in terms of the CPU detection. Quite a few other
additions. Please note that the API has slightly changed.

* [FIX] CPU detection caused crashes on PPC.
* [FIX] Script output sometimes did not get fully included.
* [CHG] Slightly changed the API and deprecated the old hooks.
* [CHG] No dialog on successful transmission.
* [ADD] Support for catching uncaught exceptions.
* [ADD] Auto-select tab.
* [ADD] Upload data asynchronously.
* [ADD] Cancel data transmission.
* [ADD] Alert dialog if transmission failed.
* [ADD] Report number of CPUs.


## Version 1.0.0, released 19.05.2008

Initial release!
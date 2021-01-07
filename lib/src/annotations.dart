/// When a class is annotated with a @Controller, 
/// it gains the ability to host observable fields
/// 
/// This is done through a precompiled dart file that
/// converts every field in the class into a getter/setter
/// 
/// The class then gains the `.toController()` and `.ctx()`
/// helper methods, both of which do the same thing.
/// These helpers convert a regular class into an observable
/// Controller class which can play nice with
/// [Synaps]
/// 
class Controller {
  const Controller();
}

/// when a field of a @Controller class is marked with @Observable,
/// it gains the ability to track whenever that specific field
///  is modified and/or read from.
/// 
class Observable {
  const Observable();
}

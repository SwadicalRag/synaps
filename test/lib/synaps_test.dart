import "package:synaps/synaps.dart";
import "package:synaps_test/samples/hello.dart";
import "package:test/test.dart";

void main() {
  group("HelloController", () {
    setUp(() {

    });

    test(".monitor() does not trigger onUpdate() for non observable fields", () {
      final hello = Hello().ctx();

      var didUpdate = false;
      SynapsMasterController.monitor(
        monitor: () {
          var stub = hello.imNormal;
        },
        onUpdate: () {
          didUpdate = true;
        }
      );

      hello.imNormal = "Small";

      expect(didUpdate,equals(false));
    });

    test(".monitor() triggers onUpdate() for observable fields", () {
      final hello = Hello().ctx();

      var didUpdate = false;
      SynapsMasterController.monitor(
        monitor: () {
          var stub = hello.world;
        },
        onUpdate: () {
          didUpdate = true;
        }
      );

      hello.world = "Chungus";

      expect(didUpdate,equals(true));
    });

    test(".monitor() does not trigger onUpdate() when an unrelated field changes", () {
      final hello = Hello().ctx();

      var didUpdate = false;
      SynapsMasterController.monitor(
        monitor: () {
          var stub = hello.world;
        },
        onUpdate: () {
          didUpdate = true;
        }
      );

      hello.imNormal = "Small";
      hello.universe = "A S C E N D E D";

      expect(didUpdate,equals(false));
    });

    test(".monitor() should trigger onUpdate for each update", () {
      final hello = Hello().ctx();

      var didUpdate = 0;
      SynapsMasterController.monitor(
        monitor: () {
          var stub = hello.world;
        },
        onUpdate: () {
          didUpdate++;
        }
      );

      hello.world = "Big";
      hello.world = "Chungus";

      expect(didUpdate,equals(2));
    });

    test(".monitor() should trigger onUpdate once if a transaction is used", () {
      final hello = Hello().ctx();

      var didUpdate = 0;
      SynapsMasterController.monitor(
        monitor: () {
          var stub = hello.world;
          var stub2 = hello.universe;
        },
        onUpdate: () {
          didUpdate++;
        }
      );


      SynapsMasterController.transaction(() {
        hello.world = "Ultra";
        hello.universe = "Chungus";
        hello.world = "Big";
      });

      expect(didUpdate,equals(1));
    });

    test(".monitor() should trigger onUpdate once for each variable if even a transaction is used", () {
      final hello = Hello().ctx();

      var didUpdate = 0;
      SynapsMasterController.monitorGranular(
        monitor: () {
          var stub = hello.world;
          var stub2 = hello.universe;
        },
        onUpdate: (symbol,newVal) {
          didUpdate++;
        }
      );


      SynapsMasterController.transaction(() {
        hello.world = "Ultra";
        hello.universe = "Chungus";
        hello.world = "Big";
      });

      expect(didUpdate,equals(2));
    });

    test(".monitor() should not trigger onUpdate if ignore is used", () {
      final hello = Hello().ctx();

      var didUpdate = 0;
      SynapsMasterController.monitor(
        monitor: () {
          var stub = hello.world;
        },
        onUpdate: () {
          didUpdate++;
        }
      );


      SynapsMasterController.ignore(() {
        hello.world = "Big";
        hello.world = "Chungus";
      });

      expect(didUpdate,equals(0));
    });
  });
}

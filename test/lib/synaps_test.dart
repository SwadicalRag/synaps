import "package:synaps/synaps.dart";
import "package:synaps_test/samples/hello.dart";
import "package:synaps_test/samples/list.dart";
import "package:synaps_test/samples/map.dart";
import "package:synaps_test/samples/reference.dart";
import "package:synaps_test/samples/set.dart";
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


  group("ListController", () {
    setUp(() {

    });

    test(".monitor() should notify on index changes", () {
      final listTest = ListTest().ctx();

      var didUpdate = false;
      SynapsMasterController.monitor(
        monitor: () {
          var stub = listTest.numberwang[0];
        },
        onUpdate: () {
          didUpdate = true;
        }
      );

      listTest.numberwang[0] = 23;

      expect(didUpdate,equals(true));
    });

    test(".monitor() should not notify on unrelated index changes", () {
      final listTest = ListTest().ctx();

      var didUpdate = false;
      SynapsMasterController.monitor(
        monitor: () {
          var stub = listTest.numberwang[0];
        },
        onUpdate: () {
          didUpdate = true;
        }
      );

      listTest.numberwang[1] = 37;

      // (by the way, that's numberwang)

      expect(didUpdate,equals(false));
    });

    test(".monitor() should notify on .add()/etc.", () {
      final listTest = ListTest().ctx();

      var didUpdate = 0;
      SynapsMasterController.monitor(
        monitor: () {
          // now, I'm told that I'm not allowed to reveal the secret numberwang formula in a public
          // repository, so this placeholder numberwang will have to do.
          // To the person who is reading this, I am sorry.
          var isNumberwang = false;

          var out = 0;
          listTest.numberwang.forEach((element) {
            out = out + element;
          });

          isNumberwang = out == 42;
        },
        onUpdate: () {
          didUpdate++;
        }
      );

      expect(didUpdate,equals(0));

      // NUMBERWAANG!!!!!
      listTest.numberwang[1] = 37;

      expect(didUpdate,equals(1));

      listTest.numberwang[1] = 21;

      expect(didUpdate,equals(2));

      // add new index
      listTest.numberwang.add(16);
      // (and yes, yes, yes, that indeed... is NUMBERWANG!)

      expect(didUpdate,equals(3));
    });
  });


  group("SetController", () {
    setUp(() {

    });

    test(".monitor() should notify on set changes", () {
      final setTest = SetTest().ctx();

      var didUpdate = 0;
      SynapsMasterController.monitor(
        monitor: () {
          if(setTest.isDisgusting()) {
            // disappointment goes here
          }
        },
        onUpdate: () {
          didUpdate++;
        }
      );

      expect(didUpdate,equals(0));

      setTest.pizzaToppings.add("tomato sauce");

      expect(didUpdate,equals(0));

      setTest.pizzaToppings.add("pineapples");

      expect(didUpdate,equals(1));
    });
  });


  group("MapController", () {
    setUp(() {

    });

    test(".monitor() should notify on map changes", () {
      final mapTest = MapTest().ctx();

      var didUpdate = 0;
      SynapsMasterController.monitor(
        monitor: () {
          // oh no it's 2 hours before my exam and i have forgotten how to read an ECG!
          // I know, I'll just ask my trusty test suite to explain everything to me!

          mapTest.explainECG((sentence) {
            // but ironically, we're not listening to anything this function says
          });
        },
        onUpdate: () {
          didUpdate++;
        }
      );

      expect(didUpdate,equals(0));

      mapTest.ecgWaves["U"] = "Purkinje fibre repolarisation";

      expect(didUpdate,equals(1));
    });

    test(".monitor() should notify only on relevant map changes", () {
      final mapTest = MapTest().ctx();

      var didUpdate = 0;
      SynapsMasterController.monitor(
        monitor: () {
          // what does the P wave do again?

          final pWave = mapTest.ecgWaves["P"];

          // I guess this is relevant too!
          mapTest.ecgWaves["delta"] = "slurred upstroke of QRS complex";
        },
        onUpdate: () {
          didUpdate++;
        }
      );

      expect(didUpdate,equals(0));

      mapTest.ecgWaves["U"] = "Purkinje fibre repolarisation";

      expect(didUpdate,equals(0));

      mapTest.ecgWaves["P"] += " following SA node activation";

      expect(didUpdate,equals(1));

      mapTest.ecgWaves["delta"] += " commonly associated with WPW";

      expect(didUpdate,equals(1));
    });
  });


  group("ReferenceController", () {
    setUp(() {

    });

    test(".monitor() should notify on value changes", () {
      final refTest = ReferenceTest().ctx();

      var didUpdate = 0;
      SynapsMasterController.monitor(
        monitor: () {
          var stub = refTest.world;
        },
        onUpdate: () {
          didUpdate++;
        }
      );

      expect(didUpdate,equals(0));

      refTest.world = Hello();

      expect(didUpdate,equals(1));
    });

    test(".monitor() should not notify on changes to fields that were never detected", () {
      final refTest = ReferenceTest().ctx();

      var didUpdate = 0;
      SynapsMasterController.monitor(
        monitor: () {
          var stub = refTest.world;
          var stub2 = refTest.world?.world;
        },
        onUpdate: () {
          didUpdate++;
        }
      );

      expect(didUpdate,equals(0));

      refTest.world = Hello();

      expect(didUpdate,equals(1));

      refTest.world.world = "boing";

      expect(didUpdate,equals(1));
    });

    test(".monitor() should notify on changes to fields inside sub controllers", () {
      final refTest = ReferenceTest().ctx();

      refTest.world = Hello();

      var didUpdate = 0;
      SynapsMasterController.monitor(
        monitor: () {
          var stub = refTest.world;
          var stub2 = refTest.world.world;
        },
        onUpdate: () {
          didUpdate++;
        }
      );

      expect(didUpdate,equals(0));

      refTest.world.world = "boing";

      expect(didUpdate,equals(1));
    });
  });
}

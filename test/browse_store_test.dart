import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/browse_store.dart';

Future<void> _prepare() async {
  SharedPreferences.setMockInitialValues({});
  await AuthStore.instance.resetForTest();
  BrowseStore.instance.resetForTest();
}

Future<void> _registra({String school = 'high-school'}) =>
    AuthStore.instance.registerManual(
      name: 'Anna Rossi',
      email: 'anna@example.com',
      password: 'segreta1',
      schoolLevelId: school,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_prepare);

  test('da ospite non c\'è nessuna scuola in visita', () {
    BrowseStore.instance.browse('university');

    expect(BrowseStore.instance.levelId, isNull);
    expect(BrowseStore.instance.isBrowsingOtherSchool, isFalse);
  });

  test('la scuola scelta è quella in visita', () async {
    await _registra();

    BrowseStore.instance.browse('university');

    expect(BrowseStore.instance.levelId, 'university');
    expect(BrowseStore.instance.isBrowsingOtherSchool, isTrue);
  });

  test('la scuola del profilo non è una visita', () async {
    await _registra();

    BrowseStore.instance.browse('high-school');

    expect(BrowseStore.instance.isBrowsingOtherSchool, isFalse);
  });

  test('reset torna alla scuola del profilo', () async {
    await _registra();
    BrowseStore.instance.browse('university');

    BrowseStore.instance.reset();

    expect(BrowseStore.instance.levelId, isNull);
  });

  test('un id vuoto non è una visita', () async {
    await _registra();

    BrowseStore.instance.browse('');

    expect(BrowseStore.instance.levelId, isNull);
  });

  test('uscire dalla sessione lascia la scuola in visita invisibile', () async {
    await _registra();
    BrowseStore.instance.browse('university');

    await AuthStore.instance.signOut();

    expect(BrowseStore.instance.levelId, isNull);
    expect(BrowseStore.instance.isBrowsingOtherSchool, isFalse);
  });

  test('il profilo non cambia quando si sfoglia un\'altra scuola', () async {
    await _registra();

    BrowseStore.instance.browse('university');

    expect(AuthStore.instance.currentUser!.schoolLevelId, 'high-school');
  });

  test('cambiare scuola non lascia residue della visita precedente', () async {
    await _registra(school: 'middle-school');
    BrowseStore.instance.browse('university');
    await AuthStore.instance.updateSchool('university');

    // La scuola appena salvata è quella del profilo, quindi non è più una visita.
    expect(BrowseStore.instance.isBrowsingOtherSchool, isFalse);
  });
}

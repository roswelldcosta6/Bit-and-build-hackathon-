import "package:flutter_test/flutter_test.dart";
import "package:signbridge/services/isl_translator.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await IslTranslator.instance.load();
  });

  test("IslTranslator full test suite per FLUTTER_INTEGRATION.md", () {
    // 1. Full phrase match
    var r = IslTranslator.instance.translate("Thank you");
    expect(r.status, TranslateStatus.complete);
    expect(r.glossSequence.map((g) => g.gloss).toList(), ["THANK_YOU"]);

    r = IslTranslator.instance.translate("thanks");
    expect(r.status, TranslateStatus.complete);
    expect(r.glossSequence.map((g) => g.gloss).toList(), ["THANK_YOU"]);

    r = IslTranslator.instance.translate("Where is home");
    expect(r.status, TranslateStatus.complete);
    expect(r.glossSequence.map((g) => g.gloss).toList(), ["WHERE", "HOME"]);

    r = IslTranslator.instance.translate("Come here");
    expect(r.status, TranslateStatus.complete);
    expect(r.glossSequence.map((g) => g.gloss).toList(), ["COME", "HERE"]);

    // 2. Multi-word collapse
    r = IslTranslator.instance.translate("do not go");
    expect(r.status, TranslateStatus.complete);
    expect(r.glossSequence.map((g) => g.gloss).toList(), ["DO_NOT", "GO"]);

    r = IslTranslator.instance.translate("does not work");
    expect(r.status, TranslateStatus.complete);
    expect(r.glossSequence.map((g) => g.gloss).toList(), ["DOES_NOT", "WORK"]);

    // 3. Hindi phrase rules
    r = IslTranslator.instance.translate("घर कहाँ है");
    expect(r.status, TranslateStatus.complete);
    expect(r.glossSequence.map((g) => g.gloss).toList(), ["WHERE", "HOME"]);

    r = IslTranslator.instance.translate("मत जाओ");
    expect(r.status, TranslateStatus.complete);
    expect(r.glossSequence.map((g) => g.gloss).toList(), ["DO_NOT", "GO"]);

    r = IslTranslator.instance.translate("आपका नाम क्या है");
    expect(r.status, TranslateStatus.complete);
    expect(r.glossSequence.map((g) => g.gloss).toList(), ["WHAT", "YOUR", "NAME"]);

    // 4. Hindi copula dropped
    r = IslTranslator.instance.translate("यह घर है");
    expect(r.status, TranslateStatus.complete);
    expect(r.glossSequence.map((g) => g.gloss).toList(), ["THIS", "HOME"]);

    // 5. Honest reporting of unknowns (no hallucinations)
    r = IslTranslator.instance.translate("I need water");
    expect(r.status, TranslateStatus.partial);
    expect(r.glossSequence.map((g) => g.gloss).toList(), ["I"]);
    expect(r.unknownWords.toSet(), {"need", "water"});

    r = IslTranslator.instance.translate("Please help me");
    expect(r.status, TranslateStatus.partial);
    expect(r.unknownWords, contains("please"));

    r = IslTranslator.instance.translate("मुझे पानी चाहिए");
    expect(r.status, TranslateStatus.partial);
    expect(r.glossSequence.map((g) => g.gloss).toList(), ["I"]);
    expect(r.unknownWords.toSet(), {"पानी", "चाहिए"});

    // 6. Unknown
    r = IslTranslator.instance.translate("xyzzy plugh");
    expect(r.status, TranslateStatus.unknown);
    expect(r.glossSequence, isEmpty);

    // 7. Empty
    r = IslTranslator.instance.translate("");
    expect(r.status, TranslateStatus.unknown);
    expect(r.glossSequence, isEmpty);
  });
}

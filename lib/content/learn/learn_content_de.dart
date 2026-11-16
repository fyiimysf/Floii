import 'learn_article.dart';

/// German copy for the Learn page.
///
/// Copy is deliberately short: three short sections per topic, one or two
/// sentences per paragraph. Emphasis uses the tiny markup understood by
/// `parseLearnSpans` in `lib/utils/learn_markup.dart`:
///
///  * `**bold**`, `_italic_`, `!!important!!`
const Map<String, LearnArticle> learnArticlesDe = {
  'basics': LearnArticle(
    title: 'Der Menstruationszyklus',
    caption: 'Was er ist, wie er gezählt wird und was ihn steuert',
    summary:
        'Der Menstruationszyklus ist die monatliche Abfolge von Veränderungen, '
        'die ein Körper vor einer Schwangerschaft durchläuft. Er endet mit '
        'einer Periode, wenn keine Schwangerschaft eintritt. Man zählt ihn '
        '**vom ersten Tag einer Periode bis zum ersten Tag der nächsten**.',
    facts: [
      LearnFact('Durchschnittliche Zykluslänge', 'Etwa 28 Tage'),
      LearnFact('Normaler Bereich bei Erwachsenen', '21 bis 35 Tage'),
      LearnFact('Dauer der Blutung', '3 bis 7 Tage'),
      LearnFact('Blutverlust pro Periode', '30 bis 40 mL'),
    ],
    sections: [
      LearnSection('Zwei Zyklen auf einmal', [
        'Der **Ovarialzyklus (Eierstockzyklus)** findet in den Eierstöcken statt. '
            'Eine Eizelle wächst in einem kleinen Bläschen, dem Follikel, heran und '
            'bricht dann aus. Das ist die _Ovulation (Eisprung)_.',
        'Der **Uteruszyklus (Gebärmutterzyklus)** findet in der Gebärmutter statt. '
            'Ihre Schleimhaut verdickt sich, um eine befruchtete Eizelle aufzunehmen. '
            'Wenn keine Eizelle ankommt, wird die Schleimhaut abgestoßen und '
            'verlässt den Körper als Periode.',
      ]),
      LearnSection('Was ihn steuert', [
        'Hormone steuern den gesamten Prozess. Das Gehirn sendet Signale an '
            'die Eierstöcke, die mit der Ausschüttung eigener Hormone antworten. '
            'Zwei davon, **FSH** und **LH**, leisten die Hauptarbeit. Ein '
            'steiler Anstieg von LH löst den Eisprung aus.',
        'Wenn eine Schwangerschaft eintritt, hält ein Hormon des neuen Embryos '
            'die Schleimhaut aufrecht. Ohne dieses fällt der Hormonspiegel ab '
            'und die Periode beginnt.',
      ]),
      LearnSection('Er ist keine Uhr', [
        'Die Zykluslänge ändert sich von Person zu Person und von Monat zu Monat. '
            '!!Der Durchschnitt von 28 Tagen ist ein Mittelwert, kein Zielwert.!!',
        'Dein Zyklus kann sich durch Stress, Krankheit, Gewichtsveränderungen, '
            'intensiven Sport, Stillen oder hormonelle Verhütung verschieben. '
            '!!Unregelmäßige Zyklen sind in den ersten Jahren nach der ersten '
            'Periode und später im Leben häufig.!!',
      ]),
    ],
  ),
  'phases': LearnArticle(
    title: 'Die vier Phasen',
    caption: 'Menstruation, Follikelphase, Eisprung und Lutealphase',
    summary:
        'Ein Zyklus hat vier Phasen. Zwei finden zu Beginn gleichzeitig statt, '
        'dann der Eisprung, gefolgt von einer kurzen Lutealphase vor der nächsten Periode. '
        '!!Nahezu die gesamte Schwankung der Zykluslänge stammt aus der Follikelphase.!!',
    facts: [
      LearnFact('Menstruationsphase', 'Etwa 3 bis 7 Tage'),
      LearnFact('Follikelphase', 'Etwa 7 bis 14 Tage'),
      LearnFact('Eisprung dauert', '24 bis 36 Stunden'),
      LearnFact('Lutealphase', 'Etwa 12 bis 14 Tage'),
    ],
    sections: [
      LearnSection('Menstruations- und Follikelphase', [
        'Die **Menstruationsphase** ist die Periode selbst, in der die '
            'Gebärmutterschleimhaut abgestoßen wird.',
        'Die **Follikelphase** beginnt am selben Tag wie deine Periode, während '
            'ein Follikel wächst und der Östrogenspiegel steigt. Diese Phase ist der '
            'variabelste Teil deines Zyklus.',
      ]),
      LearnSection('Eisprung und Lutealphase', [
        'Der **Eisprung (Ovulation)** ist die Freisetzung der Eizelle, etwa zwei '
            'Wochen vor deiner nächsten Periode. !!Er findet häufiger früher '
            'oder später als an Tag 14 statt, als viele erwarten.!!',
        'Die **Lutealphase** verläuft vom Eisprung bis zur nächsten Periode. '
            'Der verbleibende Follikel, nun Gelbkörper genannt, schüttet '
            'Progesteron aus. Diese Phase ist bemerkenswert konstant, meist 12 bis 14 Tage.',
      ]),
      LearnSection('Warum die Phasen wichtig sind', [
        'Energie, Stimmung und Ausfluss folgen meist diesen Phasen. Zu wissen, '
            'wo du dich im Zyklus befindest, kann eine schwierige Woche erklärbar '
            'statt rätselhaft machen.',
      ]),
    ],
  ),
  'symptoms': LearnArticle(
    title: 'Symptome und PMS',
    caption: 'Häufige Anzeichen, PMS, PMDS und Periodenschmerzen',
    summary:
        'Die meisten Menschen bemerken Veränderungen rund um ihre Periode. Die '
        'meisten Symptome sind mild und vergehen wieder. Eine kleinere Zahl hat '
        'so schwere Symptome, dass der Alltag gestört wird – was behandlungswürdig ist.',
    facts: [
      LearnFact('Personen mit PMS', 'Etwa 8 von 10'),
      LearnFact('Personen mit PMDS', 'Etwa 3 bis 8 von 100'),
      LearnFact('Dauer von Krämpfen', '1 bis 3 Tage'),
      LearnFact('Krämpfe werden verursacht durch', 'Prostaglandine'),
    ],
    sections: [
      LearnSection('PMS', [
        '**PMS** ist die Bezeichnung für die Gruppe von Symptomen, die in der '
            'Woche vor der Periode auftreten können: Blähungen, Brustspannen, '
            'Kopfschmerzen, Müdigkeit, Heißhunger und Stimmungsschwankungen.',
        '!!PMS ist sehr häufig und gut behandelbar.!! Symptome, die nur in '
            'der Lutealphase auftreten und nach Beginn der Periode nachlassen, '
            'sind ein starker Hinweis.',
      ]),
      LearnSection('PMDS', [
        '**PMDS** (prämenstruelle dysphorische Störung) ist eine schwerere '
            'Form, die diagnostiziert wird, wenn Symptome Arbeit, Schule oder '
            'Beziehungen ernsthaft beeinträchtigen. Im Gegensatz zu PMS kann sie '
            'einschränkend wirken.',
        'Es ist kein Charakterfehler und nicht einfach schlechte Laune. Es ist eine '
            'anerkannte Erkrankung mit echten Behandlungsmöglichkeiten, auch '
            'solchen, die vor Beginn der Periode helfen.',
      ]),
      LearnSection('Periodenschmerzen', [
        'Krämpfe entstehen durch **Prostaglandine**, Chemikalien, die die '
            'Gebärmutter sich zusammenziehen lassen. Sie sind in den ersten Tagen der '
            'Blutung am stärksten und lassen danach meist nach.',
        'Wärme, sanfte Bewegung und entzündungshemmende Schmerzmittel helfen '
            'den meisten Menschen. !!Schmerzen, die dich daran hindern, deinen '
            'Tag zu bewältigen, musst du nicht einfach hinnehmen.!!',
      ]),
    ],
  ),
  'selfCare': LearnArticle(
    title: 'Für sich selbst sorgen',
    caption: 'Kleine Dinge, die einen schwierigen Zyklus erleichtern',
    summary:
        'Du brauchst keine perfekte Routine. Ein paar Gewohnheiten helfen meist '
        'mehr als eine lange Liste von Regeln, und die meisten davon kosten nichts.',
    facts: [
      LearnFact('Schlaf', '7 bis 9 Stunden pro Nacht'),
      LearnFact('Bewegung', 'An den meisten Tagen der Woche'),
      LearnFact('Am besten bei Krämpfen', 'Wärme und sanfte Bewegung'),
      LearnFact(
          'Tracking lohnt sich für', 'Blutungsstärke, Stimmung und Schmerz'),
    ],
    sections: [
      LearnSection('Alltägliche Grundlagen', [
        '**Schlaf und Mahlzeiten** sind am wichtigsten. Das Auslassen von '
            'Mahlzeiten verschlimmert Krämpfe und Heißhunger meist eher, als '
            'dass es hilft.',
        '**Bewegung**, die zu deinem Körper passt, reicht völlig aus. Es gibt keine '
            'ideale Zyklusphase für Sport; mach also, was sich gut anfühlt, und lass '
            'weg, was nicht guttut.',
      ]),
      LearnSection('In einer schwierigen Woche', [
        'Wärme auf dem Unterleib, sanftes Dehnen oder ein Spaziergang sind verlässliche '
            'Hilfen bei Krämpfen. Reduziere Koffein, wenn es deine Symptome spürbar '
            'verschlimmert.',
        '**Schraube deine Erwartungen herunter.** Eine Woche mit gedrückter '
            'Stimmung ist vorübergehend, und darum herum zu planen ist nützlicher, '
            'als dagegen anzukämpfen.',
      ]),
      LearnSection('Nutze deine Daten', [
        'Das Verfolgen von Blutungsstärke, Stimmung und Schmerzen über einige '
            'Zyklen macht Muster leichter erkennbar. !!Was im Moment zufällig wirkt, '
            'ist oft offensichtlich, sobald es aufgeschrieben ist.!!',
      ]),
    ],
  ),
  'myths': LearnArticle(
    title: 'Häufige Mythen',
    caption: 'Was viele glauben – und was tatsächlich stimmt',
    summary: 'Viele Ratschläge zur Periode werden so lange wiederholt, bis sie '
        'selbstverständlich klingen. Hier ist das, was die Wissenschaft '
        'tatsächlich stützt.',
    facts: [
      LearnFact('Eine ausbleibende Periode bedeutet meist',
          'Schwangerschaft, bis das Gegenteil bewiesen ist'),
      LearnFact('Tampons stehen in Verbindung mit',
          'Toxischem Schocksyndrom, aber selten'),
      LearnFact('Sehr intensiver Sport kann verursachen',
          'Gelegentlich das Ausbleiben der Periode'),
      LearnFact('PMS im Vergleich zu', 'PMDS, jedoch milder'),
    ],
    sections: [
      LearnSection('Zwei Mythen, die man ablegen sollte', [
        '**Beim Stillen kann man nicht schwanger werden.** Stillen verringert '
            'zwar die Fruchtbarkeit, aber nicht zuverlässig genug, um sich allein '
            'darauf zu verlassen. !!Verwende Verhütungsmittel, wenn du nicht '
            'schwanger werden möchtest.!!',
        '**Du musst einen 28-Tage-Zyklus haben.** Spannen von 21 bis 35 Tagen '
            'sind bei Erwachsenen normal, und _dein eigener Durchschnitt ist '
            'nützlicher als jede Zahl aus einem Lehrbuch_.',
      ]),
      LearnSection('Halbwahrheiten', [
        '**Man verliert während der Periode viel Blut.** Der Durchschnitt liegt bei '
            'etwa 30 bis 40 mL, was eher wenigen Esslöffeln entspricht als dem, '
            'was sich viele vorstellen. !!Eine Binde stündlich über mehrere Stunden '
            'komplett durchzutränken, ist einen Arztbesuch wert.!!',
        '**Tampons sind gefährlich.** Sie sind sicher, wenn sie rechtzeitig '
            'gewechselt werden. Die schwere Infektion, die mit ihnen in Verbindung '
            'gebracht wird, ist selten und tritt auf, wenn man sie viel zu lange '
            'eingeführt lässt.',
      ]),
    ],
  ),
  'warningSigns': LearnArticle(
    title: 'Wann du zum Arzt gehen solltest',
    caption: 'Symptome, die eine Untersuchung verdienen',
    summary:
        'Die meisten Periodenprobleme sind alltäglich und gut behandelbar. Ein '
        'paar Anzeichen sollte man abklären lassen, anstatt abzuwarten, ob sie '
        'von selbst vergehen.',
    facts: [
      LearnFact('Arzt aufsuchen, wenn die Blutung dauert', 'Länger als 7 Tage'),
      LearnFact('Ebenfalls abklärungsbedürftig', 'Zwischenblutungen'),
      LearnFact('Dringende Hilfe holen bei',
          'Plötzlichen starken einseitigen Schmerzen'),
      LearnFact('Hilfe ist angebracht, wenn Symptome',
          'Dich daran hindern, deinen Alltag zu bewältigen'),
    ],
    sections: [
      LearnSection('Einen Termin vereinbaren', [
        'Blutungen, die **länger als sieben Tage** dauern, oder Zwischenblutungen '
            'oder Blutungen nach den Wechseljahren.',
        'Perioden, die sehr stark, sehr schmerzhaft oder plötzlich unregelmäßig '
            'werden, obwohl sie es nie waren.',
        '!!Symptome, die dich daran hindern zu arbeiten, zu lernen oder Menschen '
            'zu treffen, verdienen es, ernst genommen zu werden.!!',
      ]),
      LearnSection('Dringend Hilfe holen', [
        '**Plötzliche starke Schmerzen auf einer Seite des Unterleibs**, '
            'besonders mit Ohnmacht, Schulterschmerzen oder Blutungen. Das kann '
            'auf eine Eileiterschwangerschaft oder eine gedrehte Ovarialzyste hinweisen.',
        '**Fieber mit Unterleibsschmerzen oder übelriechendem Ausfluss**, was auf '
            'eine Infektion hinweisen kann, die Antibiotika erfordert.',
      ]),
    ],
  ),
  'firstPeriod': LearnArticle(
    title: 'Deine erste Periode',
    caption: 'Was dich erwartet und wie du dich vorbereitest',
    summary:
        'Die erste Periode trifft meist zwischen dem 9. und 16. Lebensjahr '
        'ein. Bei manchen kommt sie früher, bei anderen später, und !!eine '
        'ausbleibende erste Periode nach dem 15. Lebensjahr sollte ärztlich '
        'abgeklärt werden.!!',
    facts: [
      LearnFact('Üblicher Altersbereich', '9 bis 16 Jahre'),
      LearnFact('Abklärung empfohlen ab Alter', '15 Jahre'),
      LearnFact(
          'Wie die erste Blutung aussieht', 'Zuerst leichte Schmierblutung'),
      LearnFact('Zyklen pendeln sich oft ein innerhalb von', '2 bis 3 Jahren'),
    ],
    sections: [
      LearnSection('Was zuerst passiert', [
        '**Brustentwicklung und Schambehaarung** kommen meist zuerst, oft '
            'ein oder zwei Jahre vor der ersten Periode. Wachstums- und Größenschübe '
            'verändern sich ebenfalls kontinuierlich, nicht auf einmal.',
        'Die erste Blutung ist oft eine leichte Schmierblutung, die sich über '
            'einen oder zwei Tage verdunkelt, anstatt sofort stark zu beginnen.',
      ]),
      LearnSection('Zu Beginn unregelmäßig', [
        'In den ersten zwei Jahren sind die Zyklen oft lang, kurz oder '
            'unvorhersehbar, während sich die Hormone einpendeln. !!Eine einzelne '
            'lange Pause ist für sich genommen kein Zeichen dafür, dass etwas nicht stimmt.!!',
        'Es hilft, die Anzeichen einer Periode im Voraus zu kennen, ein Produkt '
            'bei sich zu tragen, mit dem man sich wohlfühlt, und zu wissen, wo ein '
            'Ersatzprodukt liegt. **Perioden sind nichts Schamhaftes** und du '
            'darfst überall danach fragen.',
      ]),
    ],
  ),
  'contraception': LearnArticle(
    title: 'Verhütung',
    caption: 'Die wichtigsten Optionen und wie sie funktionieren',
    summary:
        'Verhütung verhindert eine Schwangerschaft. Sie schützt nicht vor sexuell '
        'übertragbaren Infektionen, weshalb manche zwei Methoden kombinieren.',
    facts: [
      LearnFact('Kondome schützen zusätzlich vor',
          'Sexuell übertragbaren Infektionen'),
      LearnFact(
          'Schwangerschaftsrate bei der Pille', 'Etwa 7 von 100 pro Jahr'),
      LearnFact('Schwangerschaftsrate beim Kondom', 'Etwa 13 von 100 pro Jahr'),
      LearnFact('Pille danach wirkt am besten innerhalb von', '72 Stunden'),
    ],
    sections: [
      LearnSection('Die Hauptoptionen', [
        '**Kondome** verhindern, dass Spermien eine Eizelle erreichen, und '
            'senken zudem das Risiko sexuell übertragbarer Infektionen. Sie sind die '
            'einzige Option, die beides leistet.',
        '**Die Pille und das Implantat** nutzen Hormone, um den Eisprung zu '
            'verhindern. Die **Kupferspirale** funktioniert ohne Hormone. Alle sind '
            'wirksam; welche zu dir passt, hängt von deiner Gesundheit und deinen Vorlieben ab.',
      ]),
      LearnSection('Richtig anwenden', [
        'Versagensraten im Alltag sind höher als bei perfekter Anwendung, meist '
            'wegen vergessener Pillen oder unsachgemäßer Anwendung. !!Eine vergessene '
            'Dosis oder ein gerissenes Kondom ist ein guter Grund, sich nach der '
            'Notfallverhütung zu erkundigen.!!',
        'Die Pille danach wirkt umso besser, je schneller sie eingenommen '
            'wird, und schützt nicht vor einer bereits übertragenen Infektion.',
      ]),
    ],
  ),
};

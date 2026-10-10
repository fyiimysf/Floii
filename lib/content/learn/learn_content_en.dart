import 'learn_article.dart';

/// English copy for the Learn page.
///
/// Copy is deliberately short: three short sections per topic, one or two
/// sentences per paragraph. Emphasis uses the tiny markup understood by
/// `parseLearnSpans` in `lib/utils/learn_markup.dart`:
///
///  * `**bold**`, `_italic_`, `!!important!!`
const Map<String, LearnArticle> learnArticlesEn = {
  'basics': LearnArticle(
    title: 'The menstrual cycle',
    caption: 'What it is, how it is counted, and what controls it',
    summary:
        'The menstrual cycle is the monthly set of changes a body goes through '
        'before a pregnancy. It ends with a period when pregnancy does not '
        'happen. You count it **from the first day of one period to the first '
        'day of the next**.',
    facts: [
      LearnFact('Average cycle length', 'About 28 days'),
      LearnFact('Normal range in adults', '21 to 35 days'),
      LearnFact('How long bleeding lasts', '3 to 7 days'),
      LearnFact('Blood lost per period', '30 to 40 mL'),
    ],
    sections: [
      LearnSection('Two cycles at once', [
        'The **ovarian cycle** happens in the ovaries. An egg grows in a small '
            'sac called a follicle, then breaks free. This is _ovulation_.',
        'The **uterine cycle** happens inside the uterus. Its lining thickens '
            'to hold a fertilised egg. When no egg arrives, the lining is shed '
            'and leaves the body as a period.',
      ]),
      LearnSection('What controls it', [
        'Hormones run the whole process. The brain sends signals to the ovaries, '
            'which respond by releasing hormones of their own. Two of them, '
            '**FSH** and **LH**, do most of the work. A sharp rise in LH is what '
            'triggers ovulation.',
        'If pregnancy happens, a hormone from the new embryo keeps the lining '
            'in place. Without it, hormone levels drop and the period starts.',
      ]),
      LearnSection('It is not a clock', [
        'Cycle length changes from person to person, and month to month. !!The '
            '28-day average is a midpoint, not a target.!!',
        'Your cycle can shift with stress, illness, weight change, heavy '
            'exercise, breastfeeding or hormonal birth control. !!Irregular '
            'cycles are common in the first years after a first period and again '
            'later in life.!!',
      ]),
    ],
  ),
  'phases': LearnArticle(
    title: 'The four phases',
    caption: 'Menstrual, follicular, ovulation and luteal',
    summary: 'A cycle has four phases. Two happen together at the start, then '
        'ovulation, then a short luteal phase before the next period. !!Almost '
        'all of the variation in cycle length comes from the follicular '
        'phase.!!',
    facts: [
      LearnFact('Menstrual phase', 'About 3 to 7 days'),
      LearnFact('Follicular phase', 'About 7 to 14 days'),
      LearnFact('Ovulation lasts', '24 to 36 hours'),
      LearnFact('Luteal phase', 'About 12 to 14 days'),
    ],
    sections: [
      LearnSection('Menstrual and follicular', [
        '**Menstrual** is the period itself, when the uterine lining is shed.',
        '**Follicular** starts on the same day your period begins, while a '
            'follicle grows and oestrogen rises. This phase is the most '
            'variable part of your cycle.',
      ]),
      LearnSection('Ovulation and luteal', [
        '**Ovulation** is the release of the egg, roughly two weeks before your '
            'next period. !!It happens earlier or later than day 14 more often '
            'than people expect.!!',
        '**Luteal** runs from ovulation until your next period. The leftover '
            'follicle, now called the corpus luteum, releases progesterone. '
            'This phase is remarkably consistent, near 12 to 14 days.',
      ]),
      LearnSection('Why the phases matter', [
        'Energy, mood and discharge all tend to follow these phases. Knowing '
            'where you are in the cycle can make a difficult week feel '
            'explainable rather than mysterious.',
      ]),
    ],
  ),
  'symptoms': LearnArticle(
    title: 'Symptoms and PMS',
    caption: 'Common signs, PMS, PMDD and period pain',
    summary:
        'Most people notice some change around their period. Most symptoms are '
        'mild and pass. A smaller number get symptoms severe enough to disrupt '
        'daily life, which is worth treating.',
    facts: [
      LearnFact('People who get PMS', 'About 8 in 10'),
      LearnFact('People with PMDD', 'About 3 to 8 in 100'),
      LearnFact('How long cramps last', '1 to 3 days'),
      LearnFact('Cramps are caused by', 'Prostaglandins'),
    ],
    sections: [
      LearnSection('PMS', [
        '**PMS** is the name for the cluster of symptoms that can appear in the '
            'week before a period: bloating, breast tenderness, headaches, '
            'tiredness, food cravings and mood swings.',
        '!!PMS is very common and it is treatable.!! Symptoms that only ever '
            'show up in the luteal phase and ease once the period starts are a '
            'strong clue.',
      ]),
      LearnSection('PMDD', [
        '**PMDD** is a more severe form, diagnosed when symptoms seriously '
            'affect work, school or relationships. Unlike PMS it can be '
            'disabling.',
        'It is not a character flaw and not simply bad moods. It is a '
            'recognised condition with real treatments, including ones that '
            'help before a period starts.',
      ]),
      LearnSection('Period pain', [
        'Cramps come from **prostaglandins**, chemicals that make the uterus '
            'contract. They are strongest in the first days of bleeding and '
            'usually ease after that.',
        'Heat, gentle movement and anti-inflammatory painkillers help most '
            'people. !!Pain that stops you getting on with your day is not '
            'something you should simply put up with.!!',
      ]),
    ],
  ),
  'selfCare': LearnArticle(
    title: 'Looking after yourself',
    caption: 'Small things that make a difficult cycle easier',
    summary:
        'You do not need a perfect routine. A few habits tend to help more than '
        'a long list of rules, and most of them cost nothing.',
    facts: [
      LearnFact('Sleep', '7 to 9 hours a night'),
      LearnFact('Movement', 'Most days of the week'),
      LearnFact('Best for cramps', 'Heat and gentle movement'),
      LearnFact('Worth tracking', 'Flow, mood and pain'),
    ],
    sections: [
      LearnSection('Everyday basics', [
        '**Sleep and meals** matter most. Skipping meals tends to make cramps '
            'and cravings worse rather than easier.',
        '**Movement** that suits your body is enough. There is no ideal cycle '
            'phase for exercise, so do what feels good and skip what does not.',
      ]),
      LearnSection('During a difficult week', [
        'Heat on your lower abdomen, gentle stretching or a walk are reliable '
            'for cramps. Reduce caffeine if it clearly worsens your symptoms.',
        '**Lower your expectations.** A week of low mood is temporary, and '
            'planning around it is more useful than fighting it.',
      ]),
      LearnSection('Use your data', [
        'Tracking flow, mood and pain over a few cycles makes patterns easier '
            'to see. !!What looks random in the moment is often obvious once '
            'it is written down.!!',
      ]),
    ],
  ),
  'myths': LearnArticle(
    title: 'Common myths',
    caption: 'Things people often believe, and what is actually true',
    summary:
        'A lot of period advice is repeated until it sounds obvious. Here is '
        'what the evidence actually supports.',
    facts: [
      LearnFact(
          'A missed period usually means', 'Pregnancy, until proven otherwise'),
      LearnFact('Tampons are linked to', 'Toxic shock, but rarely'),
      LearnFact(
          'Very intense exercise can cause', 'A missed period, occasionally'),
      LearnFact('PMS compared with', 'PMDD, but milder'),
    ],
    sections: [
      LearnSection('Two beliefs worth dropping', [
        '**You cannot get pregnant while breastfeeding.** Breastfeeding does '
            'reduce fertility, but not reliably enough to rely on on its own. '
            '!!Use contraception if you do not want to conceive.!!',
        '**You must have a 28-day cycle.** Ranges from 21 to 35 days are '
            'normal in adults, and _your own average is more useful than any '
            'number from a textbook_.',
      ]),
      LearnSection('Half-true', [
        '**You lose a lot of blood during a period.** The average is about 30 '
            'to 40 mL, closer to a few tablespoons than to what many people '
            'imagine. !!Soaking a pad every hour for several hours is worth '
            'mentioning to a doctor.!!',
        '**Tampons are dangerous.** They are safe when changed on time. The '
            'serious infection linked to them is rare and linked to leaving '
            'one in far too long.',
      ]),
    ],
  ),
  'warningSigns': LearnArticle(
    title: 'When to see a doctor',
    caption: 'Symptoms that deserve a check-up',
    summary:
        'Most period problems are ordinary and treatable. A few signs are worth '
        'getting checked rather than waiting to see if they settle.',
    facts: [
      LearnFact('See a doctor if bleeding lasts', 'More than 7 days'),
      LearnFact('Also worth reporting', 'Bleeding between periods'),
      LearnFact('Get urgent help for', 'Sudden severe one-sided pain'),
      LearnFact(
          'Help is warranted if symptoms', 'Stop you managing daily life'),
    ],
    sections: [
      LearnSection('Book an appointment', [
        'Bleeding that lasts **longer than seven days**, or between periods, or '
            'after menopause.',
        'Periods that become very heavy, very painful or suddenly irregular '
            'when they never used to be.',
        '!!Symptoms that stop you working, studying or seeing people deserve to '
            'be taken seriously.!!',
      ]),
      LearnSection('Get urgent help', [
        '**Sudden severe pain on one side of the lower belly**, especially with '
            'fainting, shoulder pain or bleeding. This can mean an ectopic '
            'pregnancy or a twisted ovarian cyst.',
        '**Fever with pelvic pain or foul-smelling discharge**, which can mean '
            'an infection that needs antibiotics.',
      ]),
    ],
  ),
  'firstPeriod': LearnArticle(
    title: 'Your first period',
    caption: 'What to expect, and how to prepare',
    summary: 'A first period usually arrives between ages 9 and 16. It arrives '
        'earlier for some and later for others, and !!a late first period is '
        'worth mentioning to a doctor after age 15.!!',
    facts: [
      LearnFact('Usual age range', '9 to 16'),
      LearnFact('Worth a check-up after age', '15'),
      LearnFact('What the first flow looks like', 'Light spotting first'),
      LearnFact('Cycles often settle within', '2 to 3 years'),
    ],
    sections: [
      LearnSection('What happens first', [
        '**Breast development and pubic hair** usually come first, often a year '
            'or two before the first period. Growth and height also change '
            'throughout, not all at once.',
        'The first flow is often light spotting that darkens over a day or two '
            'rather than starting all at once.',
      ]),
      LearnSection('Irregular at first', [
        'For the first couple of years cycles are often long, short or '
            'unpredictable while hormones settle. !!One long gap is not on its '
            'own a sign that something is wrong.!!',
        'It helps to know the signs of a period in advance, carry a product '
            'you are comfortable with, and know where a spare is kept. '
            '**Periods are not shameful** and you are allowed to ask about '
            'them anywhere.',
      ]),
    ],
  ),
  'contraception': LearnArticle(
    title: 'Birth control',
    caption: 'The main options and how they work',
    summary:
        'Contraception prevents pregnancy. It does not protect against sexually '
        'transmitted infections, so some people use two methods.',
    facts: [
      LearnFact(
          'Condoms also protect against', 'Sexually transmitted infections'),
      LearnFact('Pregnancy rate with the pill', 'About 7 in 100 a year'),
      LearnFact('Pregnancy rate with a condom', 'About 13 in 100 a year'),
      LearnFact('Emergency pills work best within', '72 hours'),
    ],
    sections: [
      LearnSection('The main options', [
        '**Condoms** stop sperm reaching an egg and also reduce the risk of '
            'sexually transmitted infections. They are the only option that does '
            'both.',
        '**The pill and the implant** use hormones to stop an egg being '
            'released. The **copper IUD** works without hormones. All of them '
            'are effective, and which suits you depends on your health and '
            'preferences.',
      ]),
      LearnSection('Using them well', [
        'Real-world failure rates are higher than perfect-use rates, usually '
            'because of missed pills or incorrect fitting. !!A missed dose or a '
            'broken condom is a good reason to ask about emergency '
            'contraception.!!',
        'Emergency pills work best the sooner they are taken, and do not '
            'protect against an infection that has already been passed on.',
      ]),
    ],
  ),
};

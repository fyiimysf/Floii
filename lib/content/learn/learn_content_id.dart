import 'learn_article.dart';

/// Indonesian copy for the Learn page.
///
/// Copy is deliberately short: three short sections per topic, one or two
/// sentences per paragraph. Emphasis uses the tiny markup understood by
/// `parseLearnSpans` in `lib/utils/learn_markup.dart`:
///
///  * `**bold**`, `_italic_`, `!!important!!`
const Map<String, LearnArticle> learnArticlesId = {
  'basics': LearnArticle(
    title: 'Siklus menstruasi',
    caption: 'Apa itu, cara menghitungnya, dan apa yang mengontrolnya',
    summary:
        'Siklus menstruasi adalah serangkaian perubahan bulanan yang dialami '
        'tubuh sebelum kehamilan. Siklus ini diakhiri dengan haid ketika '
        'kehamilan tidak terjadi. Anda menghitungnya **dari hari pertama satu '
        'haid hingga hari pertama haid berikutnya**.',
    facts: [
      LearnFact('Rata-rata panjang siklus', 'Sekitar 28 hari'),
      LearnFact('Rentang normal pada orang dewasa', '21 hingga 35 hari'),
      LearnFact('Lama pendarahan berlangsung', '3 hingga 7 hari'),
      LearnFact('Darah yang keluar per haid', '30 hingga 40 mL'),
    ],
    sections: [
      LearnSection('Dua siklus sekaligus', [
        '**Siklus ovarium** terjadi di ovarium. Sel telur tumbuh di dalam '
            'kantung kecil yang disebut folikel, lalu lepas. Ini disebut _ovulasi_.',
        '**Siklus uterus** terjadi di dalam rahim. Lapisannya menebal untuk '
            'menampung sel telur yang dibuahi. Ketika tidak ada sel telur yang datang, '
            'lapisan tersebut luruh dan keluar dari tubuh sebagai haid.',
      ]),
      LearnSection('Apa yang mengontrolnya', [
        'Hormon menjalankan seluruh proses ini. Otak mengirimkan sinyal ke '
            'ovarium, yang merespons dengan melepaskan hormon mereka sendiri. Dua '
            'di antaranya, **FSH** dan **LH**, melakukan sebagian besar kerja. '
            'Lonjakan tajam LH adalah yang memicu ovulasi.',
        'Jika kehamilan terjadi, hormon dari embrio baru menjaga lapisan tersebut '
            'tetap di tempatnya. Tanpanya, kadar hormon menurun dan haid dimulai.',
      ]),
      LearnSection('Ini bukan jam dinding', [
        'Panjang siklus berubah dari orang ke orang, dan dari bulan ke bulan. '
            '!!Rata-rata 28 hari adalah titik tengah, bukan target.!!',
        'Siklus Anda dapat bergeser karena stres, penyakit, perubahan berat badan, '
            'olahraga berat, menyusui, atau kontrasepsi hormonal. !!Siklus tidak '
            'teratur adalah hal umum pada tahun-tahun pertama setelah haid pertama '
            'dan kembali terjadi di kemudian hari.!!',
      ]),
    ],
  ),
  'phases': LearnArticle(
    title: 'Empat fase',
    caption: 'Menstruasi, folikel, ovulasi, dan luteal',
    summary: 'Satu siklus memiliki empat fase. Dua fase terjadi bersamaan di '
        'awal, lalu ovulasi, diikuti fase luteal singkat sebelum haid berikutnya. '
        '!!Hampir semua variasi dalam panjang siklus berasal dari fase folikel.!!',
    facts: [
      LearnFact('Fase menstruasi', 'Sekitar 3 hingga 7 hari'),
      LearnFact('Fase folikel', 'Sekitar 7 hingga 14 hari'),
      LearnFact('Ovulasi berlangsung', '24 hingga 36 jam'),
      LearnFact('Fase luteal', 'Sekitar 12 hingga 14 hari'),
    ],
    sections: [
      LearnSection('Menstruasi dan folikel', [
        '**Menstruasi** adalah periode haid itu sendiri, saat lapisan rahim luruh.',
        '**Folikel** dimulai pada hari yang sama saat haid Anda mulai, ketika '
            'folikel tumbuh dan estrogen meningkat. Fase ini adalah bagian yang paling '
            'bervariasi dari siklus Anda.',
      ]),
      LearnSection('Ovulasi dan luteal', [
        '**Ovulasi** adalah pelepasan sel telur, kira-kira dua minggu sebelum haid '
            'berikutnya. !!Ini terjadi lebih awal atau lebih lambat dari hari ke-14 '
            'lebih sering daripada yang diperkirakan orang.!!',
        '**Luteal** berlangsung dari ovulasi hingga haid berikutnya. Sisa folikel, '
            'yang sekarang disebut korpus luteum, melepaskan progesteron. '
            'Fase ini sangat konsisten, sekitar 12 hingga 14 hari.',
      ]),
      LearnSection('Mengapa fase-fase ini penting', [
        'Energi, suasana hati, dan keputihan cenderung mengikuti fase-fase ini. '
            'Mengetahui di mana posisi Anda dalam siklus dapat membuat minggu '
            'yang sulit terasa dapat dijelaskan, bukan misterius.',
      ]),
    ],
  ),
  'symptoms': LearnArticle(
    title: 'Gejala dan PMS',
    caption: 'Tanda umum, PMS, PMDD, dan nyeri haid',
    summary:
        'Sebagian besar orang menyadari beberapa perubahan di sekitar masa haid '
        'mereka. Sebagian besar gejala bersifat ringan dan akan berlalu. Sebagian '
        'kecil mengalami gejala yang cukup parah hingga mengganggu kehidupan sehari-hari, '
        'yang perlu ditangani.',
    facts: [
      LearnFact('Orang yang mengalami PMS', 'Sekitar 8 dari 10'),
      LearnFact('Orang dengan PMDD', 'Sekitar 3 hingga 8 dari 100'),
      LearnFact('Lama kram berlangsung', '1 hingga 3 hari'),
      LearnFact('Kram disebabkan oleh', 'Prostaglandin'),
    ],
    sections: [
      LearnSection('PMS', [
        '**PMS** adalah nama untuk kumpulan gejala yang dapat muncul pada minggu '
            'sebelum haid: kembung, nyeri payudara, sakit kepala, kelelahan, '
            'keinginan makan, dan perubahan suasana hati.',
        '!!PMS sangat umum terjadi dan dapat diobati.!! Gejala yang hanya pernah '
            'muncul pada fase luteal dan mereda begitu haid dimulai adalah petunjuk kuat.',
      ]),
      LearnSection('PMDD', [
        '**PMDD** adalah bentuk yang lebih parah, didiagnosis ketika gejala '
            'secara serius memengaruhi pekerjaan, sekolah, atau hubungan. '
            'Tidak seperti PMS, kondisi ini dapat melumpuhkan aktivitas.',
        'Ini bukan cacat karakter dan bukan sekadar suasana hati yang buruk. Ini '
            'adalah kondisi medis yang diakui dengan perawatan nyata, termasuk '
            'yang membantu sebelum haid dimulai.',
      ]),
      LearnSection('Nyeri haid', [
        'Kram berasal dari **prostaglandin**, bahan kimia yang membuat rahim '
            'berkontraksi. Kram paling kuat pada hari-hari pertama pendarahan dan '
            'biasanya mereda setelah itu.',
        'Kompres hangat, gerakan ringan, dan obat pereda nyeri anti-inflamasi '
            'membantu sebagian besar orang. !!Nyeri yang menghentikan Anda dari '
            'menjalani hari bukanlah sesuatu yang harus Anda tahan begitu saja.!!',
      ]),
    ],
  ),
  'selfCare': LearnArticle(
    title: 'Merawat diri sendiri',
    caption: 'Hal-hal kecil yang membuat siklus sulit menjadi lebih mudah',
    summary:
        'Anda tidak memerlukan rutinitas yang sempurna. Beberapa kebiasaan '
        'cenderung membantu lebih dari sekadar daftar aturan yang panjang, dan '
        'sebagian besar tidak memerlukan biaya.',
    facts: [
      LearnFact('Tidur', '7 hingga 9 jam semalam'),
      LearnFact('Gerak tubuh', 'Hampir setiap hari dalam seminggu'),
      LearnFact('Terbaik untuk kram', 'Kompres hangat dan gerakan ringan'),
      LearnFact('Patut dilacak', 'Volume darah, suasana hati, dan nyeri'),
    ],
    sections: [
      LearnSection('Dasar-dasar sehari-hari', [
        '**Tidur dan makan** adalah yang paling penting. Melewatkan waktu makan '
            'cenderung membuat kram dan keinginan makan memburuk, bukan membaik.',
        '**Gerak tubuh** yang sesuai dengan tubuh Anda sudah cukup. Tidak ada '
            'fase siklus yang ideal untuk berolahraga, jadi lakukan apa yang terasa '
            'baik dan lewati apa yang tidak.',
      ]),
      LearnSection('Selama minggu yang sulit', [
        'Kompres hangat di perut bagian bawah, peregangan ringan, atau berjalan '
            'kaki adalah cara andal untuk meredakan kram. Kurangi kafein jika itu '
            'jelas memperburuk gejala Anda.',
        '**Turunkan ekspektasi Anda.** Minggu dengan suasana hati rendah bersifat '
            'sementara, dan merencanakannya lebih berguna daripada melawannya.',
      ]),
      LearnSection('Gunakan data Anda', [
        'Melacak pendarahan, suasana hati, dan nyeri selama beberapa siklus membuat '
            'pola lebih mudah terlihat. !!Apa yang tampak acak pada saat itu sering '
            'kali menjadi jelas setelah dituliskan.!!',
      ]),
    ],
  ),
  'myths': LearnArticle(
    title: 'Mitos umum',
    caption:
        'Hal-hal yang sering dipercayai orang, dan apa yang sebenarnya benar',
    summary:
        'Banyak saran haid diulang-ulang sampai terdengar jelas. Inilah apa yang '
        'sebenarnya didukung oleh bukti.',
    facts: [
      LearnFact('Haid yang terlambat biasanya berarti',
          'Kehamilan, kecuali terbukti sebaliknya'),
      LearnFact('Tampon dikaitkan dengan', 'Syok toksik, tetapi jarang'),
      LearnFact('Olahraga yang sangat intens dapat menyebabkan',
          'Haid terlewat, terkadang'),
      LearnFact('PMS dibandingkan dengan', 'PMDD, tetapi lebih ringan'),
    ],
    sections: [
      LearnSection('Dua kepercayaan yang layak ditinggalkan', [
        '**Anda tidak bisa hamil saat menyusui.** Menyusui memang mengurangi '
            'kesuburan, tetapi tidak cukup andal untuk diandalkan secara mandiri. '
            '!!Gunakan kontrasepsi jika Anda tidak ingin hamil.!!',
        '**Anda harus memiliki siklus 28 hari.** Rentang dari 21 hingga 35 '
            'hari adalah normal pada orang dewasa, dan _rata-rata Anda sendiri lebih '
            'berguna daripada angka apa pun dari buku teks_.',
      ]),
      LearnSection('Setengah benar', [
        '**Anda kehilangan banyak darah selama haid.** Rata-rata adalah sekitar '
            '30 hingga 40 mL, lebih dekat ke beberapa sendok makan daripada apa '
            'yang dibayangkan banyak orang. !!Membasahi pembalut hingga penuh setiap '
            'jam selama beberapa jam layak dikonsultasikan ke dokter.!!',
        '**Tampon itu berbahaya.** Tampon aman jika diganti tepat waktu. Infeksi '
            'serius yang dikaitkan dengannya jarang terjadi dan berhubungan dengan '
            'membiarkannya terpasang terlalu lama.',
      ]),
    ],
  ),
  'warningSigns': LearnArticle(
    title: 'Kapan harus ke dokter',
    caption: 'Gejala yang membutuhkan pemeriksaan',
    summary:
        'Sebagian besar masalah haid adalah hal biasa dan dapat diobati. Beberapa '
        'tanda layak diperiksakan daripada menunggu untuk melihat apakah tanda '
        'tersebut mereda.',
    facts: [
      LearnFact(
          'Konsultasi dokter jika pendarahan berlangsung', 'Lebih dari 7 hari'),
      LearnFact('Juga layak dilaporkan', 'Pendarahan di antara masa haid'),
      LearnFact('Dapatkan bantuan darurat untuk',
          'Nyeri tajam mendadak di satu sisi'),
      LearnFact('Bantuan diperlukan jika gejala',
          'Mengganggu Anda mengelola hidup sehari-hari'),
    ],
    sections: [
      LearnSection('Buat janji temu', [
        'Pendarahan yang berlangsung **lebih dari tujuh hari**, atau di antara '
            'masa haid, atau setelah menopause.',
        'Haid yang menjadi sangat deras, sangat menyakitkan, atau tiba-tiba '
            'tidak teratur padahal sebelumnya tidak pernah demikian.',
        '!!Gejala yang menghentikan Anda bekerja, belajar, atau bertemu orang '
            'lain layak untuk ditangani secara serius.!!',
      ]),
      LearnSection('Dapatkan bantuan darurat', [
        '**Nyeri hebat mendadak di satu sisi perut bagian bawah**, terutama '
            'disertai pingsan, nyeri bahu, atau pendarahan. Ini bisa berarti kehamilan '
            'ektopik atau kista ovarium yang terpuntir.',
        '**Demam dengan nyeri panggul atau keputihan berbau busuk**, yang bisa '
            'berarti infeksi yang memerlukan antibiotik.',
      ]),
    ],
  ),
  'firstPeriod': LearnArticle(
    title: 'Haid pertama Anda',
    caption: 'Apa yang diharapkan, dan cara bersiap',
    summary:
        'Haid pertama biasanya datang antara usia 9 dan 16 tahun. Ini datang '
        'lebih awal bagi sebagian orang dan lebih lambat bagi yang lain, dan !!haid '
        'pertama yang terlambat layak disampaikan ke dokter setelah usia 15 tahun.!!',
    facts: [
      LearnFact('Rentang usia umum', '9 hingga 16 tahun'),
      LearnFact('Patut diperiksakan setelah usia', '15 tahun'),
      LearnFact(
          'Seperti apa pendarahan pertama', 'Bercak ringan terlebih dahulu'),
      LearnFact('Siklus sering kali membaik dalam waktu', '2 hingga 3 tahun'),
    ],
    sections: [
      LearnSection('Apa yang terjadi terlebih dahulu', [
        '**Pertumbuhan payudara dan rambut kemaluan** biasanya muncul lebih dulu, '
            'sering kali satu atau dua tahun sebelum haid pertama. Pertumbuhan dan '
            'tinggi badan juga berubah di sepanjang masa ini, tidak sekaligus.',
        'Pendarahan pertama sering kali berupa bercak ringan yang menggelap '
            'selama satu atau dua hari daripada langsung mulai sekaligus.',
      ]),
      LearnSection('Tidak teratur pada awalnya', [
        'Selama dua tahun pertama, siklus sering kali panjang, pendek, atau '
            'tidak terprediksi saat hormon menyesuaikan diri. !!Satu jeda yang '
            'panjang bukanlah tanda bahwa ada sesuatu yang salah.!!',
        'Mengenali tanda-tanda haid terlebih dahulu, membawa produk yang nyaman '
            'bagi Anda, dan mengetahui di mana produk cadangan disimpan akan sangat '
            'membantu. **Haid bukanlah hal yang memalukan** dan Anda boleh bertanya '
            'tentang hal itu di mana saja.',
      ]),
    ],
  ),
  'contraception': LearnArticle(
    title: 'Kontrasepsi',
    caption: 'Pilihan utama dan cara kerjanya',
    summary:
        'Kontrasepsi mencegah kehamilan. Kontrasepsi tidak melindungi dari '
        'infeksi menular seksual, sehingga beberapa orang menggunakan dua metode.',
    facts: [
      LearnFact('Kondom juga melindungi dari', 'Infeksi menular seksual'),
      LearnFact('Tingkat kehamilan dengan pil', 'Sekitar 7 dari 100 per tahun'),
      LearnFact(
          'Tingkat kehamilan dengan kondom', 'Sekitar 13 dari 100 per tahun'),
      LearnFact('Pil darurat bekerja terbaik dalam waktu', '72 jam'),
    ],
    sections: [
      LearnSection('Pilihan utama', [
        '**Kondom** mencegah sperma mencapai sel telur dan juga mengurangi risiko '
            'infeksi menular seksual. Kondom adalah satu-satunya pilihan yang melakukan keduanya.',
        '**Pil dan implan** menggunakan hormon untuk menghentikan pelepasan '
            'sel telur. **IUD tembaga** bekerja tanpa hormon. Semuanya efektif, '
            'dan mana yang cocok untuk Anda tergantung pada kesehatan dan preferensi Anda.',
      ]),
      LearnSection('Menggunakannya dengan baik', [
        'Tingkat kegagalan di dunia nyata lebih tinggi daripada tingkat penggunaan '
            'sempurna, biasanya karena lupa minum pil atau pemasangan yang tidak tepat. '
            '!!Lupa minum dosis atau kondom bocor adalah alasan bagus untuk bertanya '
            'tentang kontrasepsi darurat.!!',
        'Pil darurat bekerja paling baik jika diminum lebih cepat, dan tidak '
            'melindungi dari infeksi yang sudah tertular.',
      ]),
    ],
  ),
};

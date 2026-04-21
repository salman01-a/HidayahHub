import '../models/minigames.dart';

class MinigameService {
  // Bank soal yang lebih banyak dan komprehensif
  List<MinigameQuestion> getQuestions() {
    return [
      MinigameQuestion(
        surahName: 'Al-Ikhlas',
        questionAyat: 'قُلْ هُوَ اللّٰهُ اَحَدٌۚ\n(Qul huwallāhu aḥad)',
        options: [
          'اللّٰهُ الصَّمَدُۚ (Allāhuṣ-ṣamad)',
          'لَمْ يَلِدْ وَلَمْ يُوْلَدْۙ (Lam yalid wa lam yūlad)',
          'وَلَمْ يَكُنْ لَّهٗ كُفُوًا اَحَدٌ (Wa lam yakul lahū kufuwan aḥad)',
          'مِنْ شَرِّ مَا خَلَقَۙ (Min syarri mā khalaq)',
        ],
        correctAnswerIndex: 0,
      ),
      MinigameQuestion(
        surahName: 'Al-Falaq',
        questionAyat:
            'قُلْ اَعُوْذُ بِرَبِّ الْفَلَقِۙ\n(Qul a\'ụżu birabbil-falaq)',
        options: [
          'وَمِنْ شَرِّ غَاسِقٍ اِذَا وَقَبَۙ (Wa min syarri gāsiqin iżā waqab)',
          'مِنْ شَرِّ مَا خَلَقَۙ (Min syarri mā khalaq)',
          'مَلِكِ النَّاسِۙ (Malikin-nās)',
          'اِلٰهِ النَّاسِۙ (Ilāhin-nās)',
        ],
        correctAnswerIndex: 1,
      ),
      MinigameQuestion(
        surahName: 'An-Nas',
        questionAyat: 'مَلِكِ النَّاسِۙ\n(Malikin-nās)',
        options: [
          'مِنْ شَرِّ الْوَسْوَاسِ ەۙ الْخَنَّاسِۖ (Min syarril-waswāsil-khannās)',
          'قُلْ اَعُوْذُ بِرَبِّ النَّاسِۙ (Qul a\'ụżu birabbin-nās)',
          'اِلٰهِ النَّاسِۙ (Ilāhin-nās)',
          'الَّذِيْ يُوَسْوِسُ فِيْ صُدُوْرِ النَّاسِۙ (Allażī yuwaswisu fī ṣudūrin-nās)',
        ],
        correctAnswerIndex: 2,
      ),
      MinigameQuestion(
        surahName: 'Al-Lahab',
        questionAyat:
            'تَبَّتْ يَدَآ اَبِيْ لَهَبٍ وَّتَبَّۗ\n(Tabbat yadā abī lahabiw wa tabb)',
        options: [
          'وَّامْرَاَتُهٗ ۗحَمَّالَةَ الْحَطَبِۚ (Wamra`atuh, ḥammālatal-ḥaṭab)',
          'فِيْ جِيْدِهَا حَبْلٌ مِّنْ مَّسَدٍ (Fī jīdihā ḥablum mim masad)',
          'مَآ اَغْنٰى عَنْهُ مَالُهٗ وَمَا كَسَبَۗ (Mā agnā \'anhu māluhū wa mā kasab)',
          'سَيَصْلٰى نَارًا ذَاتَ لَهَبٍۙ (Sayaṣlā nāran żāta lahab)',
        ],
        correctAnswerIndex: 2,
      ),
      MinigameQuestion(
        surahName: 'An-Nasr',
        questionAyat:
            'اِذَا جَاۤءَ نَصْرُ اللّٰهِ وَالْفَتْحُۙ\n(Iżā jā`a naṣrullāhi wal-fatḥ)',
        options: [
          'فَسَبِّحْ بِحَمْدِ رَبِّكَ وَاسْتَغْفِرْهُۗ (Fasabbiḥ biḥamdi rabbika wastagfirh)',
          'وَرَاَيْتَ النَّاسَ يَدْخُلُوْنَ فِيْ دِيْنِ اللّٰهِ اَفْوَاجًاۙ (Wa ra`aitan-nāsa yadkhulūna fī dīnillāhi afwājā)',
          'اِنَّهٗ كَانَ تَوَّابًا (Innahū kāna tawwābā)',
          'لَكُمْ دِيْنُكُمْ وَلِيَ دِيْنِ (Lakum dīnukum wa liya dīn)',
        ],
        correctAnswerIndex: 1,
      ),
      MinigameQuestion(
        surahName: 'Al-Kafirun',
        questionAyat:
            'قُلْ يٰٓاَيُّهَا الْكٰفِرُوْنَۙ\n(Qul yā ayyuhal-kāfirụn)',
        options: [
          'وَلَآ اَنْتُمْ عٰبِدُوْنَ مَآ اَعْبُدُۚ (Wa lā antum \'ābidụna mā a\'bud)',
          'لَآ اَعْبُدُ مَا تَعْبُدُوْنَۙ (Lā a\'budu mā ta\'budụn)',
          'وَلَآ اَنَا۠ عَابِدٌ مَّا عَبَدْتُّمْۙ (Wa lā ana \'ābidum mā \'abattum)',
          'لَكُمْ دِيْنُكُمْ وَلِيَ دِيْنِ (Lakum dīnukum wa liya dīn)',
        ],
        correctAnswerIndex: 1,
      ),
      MinigameQuestion(
        surahName: 'Al-Kausar',
        questionAyat:
            'اِنَّآ اَعْطَيْنٰكَ الْكَوْثَرَۗ\n(Innā a\'ṭainākal-kauṡar)',
        options: [
          'اِنَّ شَانِئَكَ هُوَ الْاَبْتَرُ (Inna syāni`aka huwal-abtar)',
          'فَصَلِّ لِرَبِّكَ وَانْحَرْۗ (Fa ṣalli lirabbika wan-ḥar)',
          'اَلَّذِيْ يُطْعِمُهُمْ مِّنْ جُوْعٍۙ (Allażī yuṭ\'imuhum min jụ\')',
          'وَّيَمْنَعُوْنَ الْمَاعُوْنَ (Wa yamna\'ụnal-mā\'ụn)',
        ],
        correctAnswerIndex: 1,
      ),
      MinigameQuestion(
        surahName: 'Al-Ma\'un',
        questionAyat:
            'اَرَاَيْتَ الَّذِيْ يُكَذِّبُ بِالدِّيْنِۗ\n(Ara`aitallażī yukażżibu bid-dīn)',
        options: [
          'فَذٰلِكَ الَّذِيْ يَدُعُّ الْيَتِيْمَۙ (Fa żālikallażī yadu\'\'ul-yatīm)',
          'وَلَا يَحُضُّ عَلٰى طَعَامِ الْمِسْكِيْنِۗ (Wa lā yaḥuḍḍu \'alā ṭa\'āmil-miskīn)',
          'فَوَيْلٌ لِّلْمُصَلِّيْنَۙ (Fa wailul lil-muṣallīn)',
          'اَلَّذِيْنَ هُمْ يُرَاۤءُوْنَۙ (Allażīna hum yurā`ụn)',
        ],
        correctAnswerIndex: 0,
      ),
      MinigameQuestion(
        surahName: 'Quraish',
        questionAyat: 'لِاِيْلٰفِ قُرَيْشٍۙ\n(Li`īlāfi quraīsy)',
        options: [
          'فَلْيَعْبُدُوْا رَبَّ هٰذَا الْبَيْتِۙ (Falya\'budụ rabba hāżal-bait)',
          'اَلَّذِيْٓ اَطْعَمَهُمْ مِّنْ جُوْعٍ ەۙ وَاٰمَنَهُمْ مِّـنْ خَوْفٍ (Allażī aṭ\'amahum min jụ\'iw wa āmanahum min khauf)',
          'اٖلٰفِهِمْ رِحْلَةَ الشِّتَاۤءِ وَالصَّيْفِۚ (Īlāfihim riḥlatasy-syitā`i waṣ-ṣaīf)',
          'تَرْمِيْهِمْ بِحِجَارَةٍ مِّنْ سِجِّيْلٍۙ (Tarmīhim biḥijāratim min sijjīl)',
        ],
        correctAnswerIndex: 2,
      ),
      MinigameQuestion(
        surahName: 'Al-Fil',
        questionAyat:
            'اَلَمْ تَرَ كَيْفَ فَعَلَ رَبُّكَ بِاَصْحٰبِ الْفِيْلِۗ\n(Alam tara kaifa fa\'ala rabbuka bi`aṣ-ḥābil-fīl)',
        options: [
          'وَّاَرْسَلَ عَلَيْهِمْ طَيْرًا اَبَابِيْلَۙ (Wa arsala \'alaihim ṭairan abābīl)',
          'اَلَمْ يَجْعَلْ كَيْدَهُمْ فِيْ تَضْلِيْلٍۙ (Alam yaj\'al kaidahum fī taḍlīl)',
          'فَجَعَلَهُمْ كَعَصْفٍ مَّأْكُوْلٍ (Fa ja\'alahum ka\'aṣfim ma`kụl)',
          'تَرْمِيْهِمْ بِحِجَارَةٍ مِّنْ سِجِّيْلٍۙ (Tarmīhim biḥijāratim min sijjīl)',
        ],
        correctAnswerIndex: 1,
      ),
    ];
  }
}

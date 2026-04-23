import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  String _lang = 'sw';

  @override
  Widget build(BuildContext context) {
    final isSw = _lang == 'sw';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D1800),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          isSw ? 'Masharti na Vigezo' : 'Terms & Conditions',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _lang,
                dropdownColor: const Color(0xFF3D1800),
                icon: const Icon(Icons.language, color: Colors.white, size: 18),
                style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13),
                items: const [
                  DropdownMenuItem(value: 'sw', child: Text('Kiswahili')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _lang = val);
                },
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Text(
                    isSw ? 'Masharti na Vigezo' : 'Terms and Conditions',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A0A00),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kreative Karakana',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE87722),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSw
                        ? 'Ilisasishwa: 12 Agosti 2025'
                        : 'Last Updated: 12 August 2025',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: const Color(0xFF9E8070),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Color(0xFFE8D5C8)),
            const SizedBox(height: 20),

            // Intro paragraph
            _body(isSw
                ? 'Kreative Karakana ("sisi", "yetu", "kutupatia") imejitolea kulinda faragha yako. Sera hii ya Faragha inaeleza jinsi tunavyokusanya, kutumia, kufichua, na kulinda taarifa unapotumia programu ya simu ya Karakana ("App"), ambayo hutoa mafunzo ya ujasiriamali yaliyolokalishwa, zana za vitendo za biashara, na huduma za kidijitali nafuu kwa MSME nchini Tanzania na kwingineko.'
                : 'Kreative Karakana ("we", "our", "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard information when you use the Karakana mobile application ("App"), which provides localized entrepreneurship learning, practical business tools, and affordable digital services to MSMEs across Tanzania and beyond.'),

            const SizedBox(height: 24),
            _section(
              isSw ? '1. Kukubaliana na Masharti' : '1. Acceptance of Terms',
              isSw
                  ? 'Kwa kufikia na kutumia huduma zinazotolewa na Kreative Karakana, unathibitisha kuwa umesoma, umeelewa, na unakubali kufungwa na Masharti na Vigezo hivi. Iwapo hukubaliani na sehemu yoyote ya masharti haya, hupaswi kutumia huduma zetu.'
                  : 'By accessing and using the services provided by Kreative Karakana, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions. If you do not agree with any part of these terms, you must not use our services.',
            ),
            _section(
              isSw ? '2. Muhtasari' : '2. Summary',
              isSw
                  ? 'Tunakusanya tu kile tunachohitaji ili kuunda akaunti yako, kuwasilisha kozi na zana, kuchakata malipo, kulinda usalama wa App, na kuboresha matumizi yako. Hatuzuizi taarifa zako binafsi kwa wauzaji wengine.\n\nTaarifa Tunazokusanya\n\na) Taarifa Binafsi Unazotoa\n• Jina, barua pepe, namba ya simu, jinsia, eneo (jiji/mkoa)\n• Hiari: picha ya wasifu, jina/aina ya biashara, sekta, maslahi\n• Ujumbe unayotutumia (msaada na maoni)\n\nb) Malipo na Muamala\n• Kwa ununuzi wa kidijitali ndani ya App, tunatumia Google Play Billing.\n• Kwa ununuzi unaofanywa kwenye tovuti yetu, tunaweza kutumia milango ya malipo ya ndani (mfano AzamPay, Mitandao ya sim).\n• Hatuhifadhi maelezo kamili ya vyombo vya malipo kwenye seva zetu.\n\nc) Taarifa za Kifaa na Matumizi\n• Aina ya kifaa, toleo la mfumo wa uendeshaji, anwani ya IP, lugha\n• Shughuli ndani ya App (ukurasa uliotembelewa, vipengele vilivyotumiwa), vikao na tathmini za hitilafu\n• Eneo la kukadiriwa (kutokana na IP) ili kulokalisha maudhui na kupima usambazaji\n\nd) Vidakuzi / Hifadhi ya Ndani\n• Hutumika kukumbuka mipangilio yako na kukuweka ndani ya Karakana App.'
                  : 'We collect only what we need to create your account, deliver courses and tools, process payments, keep the App secure, and improve your experience. We do not sell your personal data.\n\nInformation We Collect\n\na) Personal Information you provide\n• Name, email, phone number, gender, location (city/region)\n• Optional: profile photo, business name/type, sector, interests\n• Messages you send us (support and feedback)\n\nb) Payments & Transactions\n• For in-app purchases of digital content consumed in the App, we use Google Play Billing.\n• For purchases made on our website, we may use local gateways (e.g., AzamPay, mobile money).\n• We do not store full payment instrument details on our servers.\n\nc) Device & Usage Data\n• Device model, operating system version, IP address, language\n• App activity (screens visited, features used), session and crash diagnostics\n• Approximate location (derived from IP) to localize content and measure reach\n\nd) Cookies / Local Storage\n• Used to remember your settings and keep you signed in.',
            ),
            _section(
              isSw
                  ? '3. Jinsi Tunavyotumia Taarifa Zako'
                  : '3. How We Use Your Information',
              isSw
                  ? '• Unda na kudhibiti akaunti na wasifu wako\n• Toa kozi, vipengele vya ushauri, na zana za biashara\n• Shughulikia manunuzi na usajili (ikiwa ni pamoja na kupitia Google Play Billing kwa maudhui ya kidijitali ndani ya App)\n• Toa msaada, tuma taarifa muhimu, na kujibu maombi\n• Boresha utendaji, uaminifu, upatikanaji, na usalama wa App\n• Fanya uchanganuzi ili kuelewa ushiriki na kupima athari (mfano: takwimu za jinsia/vijana)\n• Tuma masasisho ya hiari kuhusu kozi, zana, au vipengele vipya (unaweza kujiondoa)'
                  : '• Create and manage your account and profile\n• Deliver courses, mentorship features, and business tools\n• Process purchases and subscriptions (including via Google Play Billing for in-app digital content)\n• Provide support, send important notices, and respond to requests\n• Improve performance, reliability, accessibility, and security of the App\n• Conduct analytics to understand engagement and measure impact (e.g., gender/youth metrics)\n• Send optional updates about new courses, tools, or features (you may opt out)',
            ),
            _section(
              isSw
                  ? '4. Misingi ya Kisheria (ikihitajika)'
                  : '4. Legal Bases (where applicable)',
              isSw
                  ? 'Tunasindika taarifa zako ili kutekeleza makubaliano na wewe, kutimiza matakwa ya kisheria, na kwa misingi ya maslahi yetu halali katika kuendesha, kulinda, na kuboresha App. Pale inapohitajika, tunapata ridhaa yako (mfano kwa mawasiliano fulani).'
                  : 'We process your information to perform a contract with you, to comply with law, and based on our legitimate interests in operating, securing, and improving the App. Where required, we obtain your consent (e.g., for certain communications).',
            ),
            _section(
              isSw ? '5. Matumizi ya Jukwaa' : '5. Use of the Platform',
              isSw
                  ? 'Unakubali kutumia jukwaa letu kwa madhumuni halali pekee na kwa mujibu wa Masharti haya. Huwezi kutumia huduma zetu kusambaza, kueneza, au kuhifadhi maudhui ambayo ni kinyume cha sheria, hatarishi, ya kutisha, ya matusi, ya unyanyasaji, ya kudhalilisha, ya matusi machafu, ya aibu, au kwa njia nyingine yoyote yasiyokubalika.'
                  : 'You agree to use our platform only for lawful purposes and in accordance with these Terms. You may not use our services to transmit, distribute, or store material that is unlawful, harmful, threatening, abusive, harassing, defamatory, vulgar, obscene, or otherwise objectionable.',
            ),
            _section(
              isSw ? '6. Jinsi Tunavyoshiriki Taarifa' : '6. How We Share Information',
              isSw
                  ? 'Hatuzui taarifa zako binafsi. Tunaweza kushiriki taarifa chache:\n• Na watoa huduma wanaoendesha App, kushughulikia malipo, kutuma arifa, au kutoa uchanganuzi/taarifa za hitilafu\n• Na washauri/mafundi ambao umechagua kuwasiliana nao au kushirikiana nao\n• Ili kutimiza wajibu wa kisheria au kulinda haki, usalama, na ulinzi\n• Katika mchakato wa uhamisho wa biashara (kwa kutoa taarifa inapohitajika)'
                  : 'We do not sell your personal data. We may share limited data:\n• With service providers that host the App, process payments, send notifications, or provide analytics/crash reporting\n• With mentors/trainers you explicitly choose to contact or engage with\n• To comply with legal obligations or protect rights, safety, and security\n• In connection with a business transfer (with notice where required)',
            ),
            _section(
              isSw
                  ? '7. Huduma na SDK za Watu Wengine'
                  : '7. Third-Party Services & SDKs',
              isSw
                  ? 'Tunaweza kutumia SDK za watu wengine kama vile Firebase Analytics na Firebase Crashlytics ili kuelewa utendaji na uaminifu wa App. Watoa huduma hawa wanaweza kupokea vitambulisho vya kifaa, taarifa za utambuzi wa hitilafu na matumizi kwa madhumuni ya kutupatia huduma hizo pekee. Tunawataka watoa huduma wetu kulinda taarifa zako na kuitumia tu chini ya maelekezo yetu.'
                  : 'We may use third-party SDKs such as Firebase Analytics and Firebase Crashlytics to understand App performance and reliability. These providers may receive device identifiers, diagnostics, and usage data solely to provide their services to us. We require our providers to protect your data and use it only under our instructions.',
            ),
            _section(
              isSw ? '8. Mali ya Kiakili' : '8. Intellectual Property',
              isSw
                  ? 'Yote yaliyomo, alama za biashara, nembo, na mali ya kiakili kwenye jukwaa letu vinamilikiwa na Kreative Karakana au watoa ruhusa wetu. Huwezi kuzalisha tena, kusambaza, kubadilisha, au kuunda kazi za urithi kutoka kwenye yaliyomo yetu bila ruhusa yetu maalum ya maandishi.'
                  : 'All content, trademarks, logos, and intellectual property on our platform are owned by Kreative Karakana or our licensors. You may not reproduce, distribute, modify, or create derivative works of our content without our express written permission.',
            ),
            _section(
              isSw ? '9. Malipo na Marejesho' : '9. Payments and Refunds',
              isSw
                  ? 'Malipo yote kwa huduma zetu hushughulikiwa kwa usalama kupitia washirika wetu wa malipo. Sera za marejesho zinatofautiana kulingana na huduma na zitafahamishwa wazi wakati wa ununuzi. Tunahifadhi haki ya kubadilisha bei zetu wakati wowote kwa kutoa taarifa inayofaa.'
                  : 'All payments for our services are processed securely through our payment partners. Refund policies vary by service and will be clearly communicated at the time of purchase. We reserve the right to modify our pricing at any time with appropriate notice.',
            ),
            _section(
              isSw ? '10. Sera ya Faragha' : '10. Privacy Policy',
              isSw
                  ? 'Faragha yako ni muhimu kwetu. Sera Yetu ya Faragha inaeleza jinsi tunavyokusanya, kutumia, na kulinda taarifa zako binafsi. Kwa kutumia huduma zetu, unakubali ukusanyaji na matumizi ya taarifa zako kama ilivyoelezwa katika Sera Yetu ya Faragha.'
                  : 'Your privacy is important to us. Our Privacy Policy explains how we collect, use, and protect your personal information. By using our services, you consent to the collection and use of your information as described in our Privacy Policy.',
            ),
            _section(
              isSw
                  ? '11. Kauli ya Kuepuka Uwajibikaji na Kizuizi cha Uwajibikaji'
                  : '11. Disclaimer and Limitation of Liability',
              isSw
                  ? 'Huduma zetu zinatolewa "kama zilivyo" bila dhamana yoyote. Kreative Karakana haitawajibika kwa hasara yoyote isiyo ya moja kwa moja, ya ajali, maalum, au ya matokeo kutokana na matumizi yako ya huduma zetu. Uwajibikaji wetu jumla hautazidi kiasi ulicholipia kwa huduma zetu.'
                  : "Our services are provided 'as is' without warranties of any kind. Kreative Karakana shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of our services. Our total liability shall not exceed the amount paid by you for our services.",
            ),
            _section(
              isSw ? '12. Kusitisha' : '12. Termination',
              isSw
                  ? 'Tunaweza kusitisha au kufungia akaunti yako na upatikanaji wa huduma zetu wakati wowote, iwe na sababu au bila, na iwe na taarifa au bila. Baada ya kusitishwa, haki yako ya kutumia huduma zetu itakwisha mara moja, na data yoyote inayohusiana na akaunti yako inaweza kufutwa.'
                  : 'We may terminate or suspend your account and access to our services at any time, with or without cause, and with or without notice. Upon termination, your right to use our services will cease immediately, and any data associated with your account may be deleted.',
            ),
            _section(
              isSw ? '13. Mabadiliko ya Masharti' : '13. Changes to the Terms',
              isSw
                  ? 'Tunahifadhi haki ya kubadilisha Masharti na Vigezo hivi wakati wowote. Tutawaarifu watumiaji kuhusu mabadiliko yoyote muhimu kwa kuchapisha masharti yaliyosasishwa kwenye jukwaa letu. Kuendelea kutumia huduma zetu baada ya mabadiliko kama hayo kunahesabiwa kama kukubali masharti mapya.'
                  : 'We reserve the right to modify these Terms and Conditions at any time. We will notify users of any material changes by posting the updated terms on our platform. Your continued use of our services after such changes constitutes acceptance of the new terms.',
            ),
            _section(
              isSw ? '14. Sheria Zinazotumika' : '14. Governing Law',
              isSw
                  ? 'Masharti na Vigezo hivi vitatawaliwa na kufasiriwa kwa mujibu wa sheria za Tanzania. Migogoro yoyote inayotokana na masharti haya itakuwa chini ya mamlaka ya kipekee ya mahakama za Tanzania.'
                  : 'These Terms and Conditions shall be governed by and construed in accordance with the laws of Tanzania. Any disputes arising from these terms shall be subject to the exclusive jurisdiction of the courts of Tanzania.',
            ),

            // Section 15: Contact Us
            _sectionTitle(isSw ? '15. Wasiliana Nasi' : '15. Contact Us'),
            const SizedBox(height: 8),
            _body(isSw
                ? 'Iwapo una maswali yoyote kuhusu Masharti na Vigezo hivi, tafadhali wasiliana nasi:'
                : 'If you have any questions about these Terms and Conditions, please contact us:'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8D5C8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _body(isSw
                      ? 'Barua Pepe: info@kreativekarakana.co.tz'
                      : 'Email: info@kreativekarakana.co.tz'),
                  const SizedBox(height: 8),
                  _body(isSw
                      ? 'Anuani: Sido (Mwemberadu), Kigamboni'
                      : 'Address: Sido (Mwemberadu), Kigamboni'),
                  const SizedBox(height: 4),
                  _body('Dar-es-Salaam, Tanzania'),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Divider(color: Color(0xFFE8D5C8)),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '©️ 2025 Kreative Karakana. All Rights Reserved.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: const Color(0xFF9E8070),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF3D1800),
      ),
    );
  }

  Widget _body(String text) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 14,
        color: const Color(0xFF3D1800),
        height: 1.6,
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title),
          const SizedBox(height: 8),
          _body(body),
        ],
      ),
    );
  }
}

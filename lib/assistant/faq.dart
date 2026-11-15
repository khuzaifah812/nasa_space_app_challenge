// The assistant's memory: answers to questions farmers ask most often.
// It needs no internet. Each entry has keywords (in all six languages) and
// one short answer per language. To add a question, add an entry here.
import '../l10n/strings.dart';

class Faq {
  const Faq(this.keywords, this.answers);
  final List<String> keywords;
  final Map<String, String> answers;
}

const faqs = <Faq>[
  Faq(['crop rotation', 'what is rotation', 'why rotate', 'rotation des cultures', 'mzunguko wa mazao', 'rotação de culturas', 'الدورة الزراعية', 'rotación de cultivos'], {
    'en': 'Crop rotation means growing a different crop on the same field each season. It restores nutrients, breaks pest and disease cycles, and spreads risk, so yields stay steadier over the years.',
    'fr': 'La rotation des cultures consiste à changer de culture sur le même champ à chaque saison. Elle restaure les nutriments, casse les cycles des ravageurs et des maladies, et répartit les risques.',
    'sw': 'Mzunguko wa mazao ni kupanda zao tofauti kwenye shamba lilelile kila msimu. Hurudisha rutuba, huvunja mizunguko ya wadudu na magonjwa, na hupunguza hatari.',
    'pt': 'A rotação de culturas é cultivar uma cultura diferente no mesmo campo em cada estação. Repõe nutrientes, quebra os ciclos de pragas e doenças e reparte o risco.',
    'ar': 'الدورة الزراعية هي زراعة محصول مختلف في الحقل نفسه كل موسم. تعيد العناصر الغذائية للتربة، وتقطع دورات الآفات والأمراض، وتوزّع المخاطر.',
    'es': 'La rotación de cultivos es sembrar un cultivo distinto en el mismo campo cada temporada. Repone nutrientes, corta los ciclos de plagas y enfermedades y reparte el riesgo.',
  }),
  Faq(['cover crop', 'culture de couverture', 'zao la kufunika', 'cultura de cobertura', 'محصول تغطية', 'cultivo de cobertura'], {
    'en': 'A cover crop is grown to protect the soil between main crops, not to sell. It stops erosion, holds water, adds organic matter, and legume cover crops such as mucuna also add nitrogen.',
    'fr': 'Une culture de couverture protège le sol entre deux cultures principales ; elle n\'est pas vendue. Elle freine l\'érosion, retient l\'eau, apporte de la matière organique, et les légumineuses ajoutent de l\'azote.',
    'sw': 'Zao la kufunika hupandwa kulinda udongo kati ya mazao makuu, si kwa kuuza. Huzuia mmomonyoko, hushika maji, huongeza mboji, na mikunde kama mucuna huongeza naitrojeni.',
    'pt': 'Uma cultura de cobertura protege o solo entre culturas principais; não é para vender. Trava a erosão, guarda água, acrescenta matéria orgânica, e as leguminosas juntam azoto.',
    'ar': 'محصول التغطية يُزرع لحماية التربة بين المحاصيل الرئيسية لا للبيع. يمنع التعرية ويحفظ الماء ويضيف مادة عضوية، والبقوليات منه تضيف النيتروجين.',
    'es': 'Un cultivo de cobertura protege el suelo entre cultivos principales; no es para vender. Frena la erosión, retiene agua, aporta materia orgánica, y las leguminosas añaden nitrógeno.',
  }),
  Faq(['mulch', 'paillage', 'paillis', 'matandazo', 'cobertura morta', 'تغطية التربة', 'نشارة', 'acolchado', 'mantillo'], {
    'en': 'Mulching is covering the soil with dry grass, crop residue or leaves. It keeps the soil moist and cool, suppresses weeds, and feeds the soil as it rots.',
    'fr': 'Le paillage consiste à couvrir le sol d\'herbe sèche, de résidus ou de feuilles. Il garde le sol humide et frais, limite les mauvaises herbes et nourrit le sol en se décomposant.',
    'sw': 'Matandazo ni kufunika udongo kwa nyasi kavu, masalia ya mazao au majani. Huhifadhi unyevu, hupunguza magugu, na hurutubisha udongo yanapooza.',
    'pt': 'Cobrir o solo com capim seco, restolho ou folhas mantém-no húmido e fresco, trava as ervas daninhas e alimenta o solo ao decompor-se.',
    'ar': 'التغطية هي فرش التربة بالعشب الجاف أو بقايا المحاصيل أو الأوراق. تحفظ رطوبة التربة وبرودتها، وتحدّ من الأعشاب، وتغذي التربة عند تحللها.',
    'es': 'El acolchado es cubrir el suelo con pasto seco, rastrojo u hojas. Mantiene el suelo húmedo y fresco, frena las malezas y alimenta el suelo al descomponerse.',
  }),
  Faq(['compost', 'manure', 'fumier', 'mboji', 'samadi', 'estrume', 'composto', 'سماد عضوي', 'كمبوست', 'estiércol', 'composta'], {
    'en': 'Compost and well-rotted manure add organic matter, which helps soil hold water and nutrients. Apply them before planting and mix into the topsoil; fresh manure can burn young plants.',
    'fr': 'Le compost et le fumier bien décomposé apportent de la matière organique, qui aide le sol à retenir l\'eau et les nutriments. Appliquez-les avant le semis ; le fumier frais peut brûler les jeunes plants.',
    'sw': 'Mboji na samadi iliyooza vizuri huongeza viumbe hai kwenye udongo, vinavyosaidia kushika maji na rutuba. Weka kabla ya kupanda; samadi mbichi inaweza kuunguza miche.',
    'pt': 'Composto e estrume bem curtido acrescentam matéria orgânica, que ajuda o solo a guardar água e nutrientes. Aplique antes da sementeira; estrume fresco pode queimar as plantas novas.',
    'ar': 'الكمبوست والسماد البلدي المتحلل جيدًا يضيفان مادة عضوية تساعد التربة على حفظ الماء والعناصر. أضفهما قبل الزراعة؛ السماد الطازج قد يحرق البادرات.',
    'es': 'El compost y el estiércol bien descompuesto aportan materia orgánica, que ayuda al suelo a retener agua y nutrientes. Aplícalos antes de sembrar; el estiércol fresco puede quemar las plántulas.',
  }),
  Faq(['soil test', 'soil ph', ' ph ', 'acid soil', 'analyse de sol', 'sol acide', 'kupima udongo', 'análise de solo', 'solo ácido', 'تحليل التربة', 'تربة حمضية', 'análisis de suelo', 'suelo ácido'], {
    'en': 'A soil test tells you the pH and nutrient levels, so you add only what the soil lacks. Most crops prefer pH 5.5 to 7; below that, lime helps. Ask your district agricultural office where to test.',
    'fr': 'Une analyse de sol indique le pH et les nutriments, pour n\'apporter que ce qui manque. La plupart des cultures préfèrent un pH de 5,5 à 7 ; en dessous, la chaux aide. Renseignez-vous auprès du service agricole.',
    'sw': 'Kipimo cha udongo huonyesha pH na virutubisho, ili uongeze kinachokosekana tu. Mazao mengi hupenda pH 5.5 hadi 7; chini ya hapo, chokaa husaidia. Uliza ofisi ya kilimo ya wilaya.',
    'pt': 'Uma análise de solo mostra o pH e os nutrientes, para juntar só o que falta. A maioria das culturas prefere pH 5,5 a 7; abaixo disso, a cal ajuda. Pergunte nos serviços agrícolas do distrito.',
    'ar': 'تحليل التربة يبيّن درجة الحموضة ومستوى العناصر، فتضيف ما ينقص فقط. معظم المحاصيل تفضّل حموضة بين 5.5 و7؛ وتحت ذلك يفيد الجير. اسأل مكتب الزراعة في منطقتك.',
    'es': 'Un análisis de suelo indica el pH y los nutrientes, para añadir solo lo que falta. La mayoría de cultivos prefiere pH 5,5 a 7; por debajo, la cal ayuda. Pregunta en la oficina agrícola de tu distrito.',
  }),
  Faq(['drought', 'dry season', 'no rain', 'sécheresse', 'ukame', 'kiangazi', 'seca', 'estiagem', 'جفاف', 'sequía'], {
    'en': 'For dry seasons: choose drought-tolerant crops such as cassava, sorghum or cowpea, plant early-maturing varieties at the first good rain, mulch the soil, and avoid leaving it bare.',
    'fr': 'En saison sèche : choisissez des cultures tolérantes comme le manioc, le sorgho ou le niébé, semez des variétés précoces dès la première bonne pluie, paillez le sol et ne le laissez pas nu.',
    'sw': 'Kwa misimu ya ukame: chagua mazao yanayostahimili kama muhogo, mtama au kunde, panda mbegu za muda mfupi mvua ya kwanza inaponyesha, tandaza matandazo, na usiache udongo wazi.',
    'pt': 'Para a seca: escolha culturas tolerantes como mandioca, sorgo ou feijão-frade, semeie variedades precoces na primeira boa chuva, cubra o solo e não o deixe nu.',
    'ar': 'لمواسم الجفاف: اختر محاصيل متحملة مثل الكسافا والذرة الرفيعة واللوبيا، وازرع أصنافًا مبكرة النضج مع أول مطر جيد، وغطِّ التربة ولا تتركها عارية.',
    'es': 'Para la sequía: elige cultivos tolerantes como yuca, sorgo o caupí, siembra variedades precoces con la primera buena lluvia, acolcha el suelo y no lo dejes desnudo.',
  }),
  Faq(['armyworm', 'chenille légionnaire', 'viwavi jeshi', 'lagarta-do-cartucho', 'دودة الحشد', 'gusano cogollero'], {
    'en': 'Fall armyworm attacks maize leaves and the funnel. Scout twice a week from emergence, crush egg masses and young caterpillars, rotate with legumes, and ask an extension officer about approved treatments before spraying.',
    'fr': 'La chenille légionnaire d\'automne attaque les feuilles et le cornet du maïs. Inspectez deux fois par semaine, écrasez œufs et jeunes chenilles, alternez avec des légumineuses, et consultez un agent avant de traiter.',
    'sw': 'Viwavi jeshi hushambulia majani na moyo wa mahindi. Kagua mara mbili kwa wiki tangu kuota, ponda mayai na viwavi wadogo, zungusha na mikunde, na muulize afisa ugani kuhusu dawa zilizoidhinishwa kabla ya kupulizia.',
    'pt': 'A lagarta-do-cartucho ataca as folhas e o cartucho do milho. Inspeccione duas vezes por semana, esmague ovos e lagartas pequenas, alterne com leguminosas e consulte um técnico antes de pulverizar.',
    'ar': 'دودة الحشد الخريفية تهاجم أوراق الذرة وقمتها. افحص الحقل مرتين أسبوعيًا منذ الإنبات، واسحق كتل البيض واليرقات الصغيرة، وناوب مع البقوليات، واستشر المرشد قبل الرش.',
    'es': 'El gusano cogollero ataca las hojas y el cogollo del maíz. Revisa dos veces por semana desde la emergencia, aplasta huevos y larvas pequeñas, rota con leguminosas y consulta a un técnico antes de fumigar.',
  }),
  Faq(['store', 'storage', 'aflatoxin', 'post-harvest', 'stockage', 'conserver', 'kuhifadhi', 'sumu kuvu', 'armazenar', 'aflatoxina', 'تخزين', 'أفلاتوكسين', 'almacenar', 'almacenamiento'], {
    'en': 'Dry grain well before storing: it should crack, not dent, when bitten. Store in clean airtight bags or containers off the ground. Damp maize and groundnuts grow moulds that make aflatoxin, which is harmful.',
    'fr': 'Séchez bien les grains avant de les stocker : ils doivent casser net sous la dent. Conservez-les dans des sacs hermétiques propres, surélevés. Maïs et arachides humides développent des moisissures à aflatoxine, dangereuse.',
    'sw': 'Kausha nafaka vizuri kabla ya kuhifadhi: ivunjike, isibonyee, ukiing\'ata. Hifadhi kwenye mifuko safi isiyopitisha hewa, juu ya chaga. Mahindi na karanga zenye unyevu huota ukungu wenye sumu kuvu.',
    'pt': 'Seque bem o grão antes de guardar: deve partir, não amolgar, ao trincar. Guarde em sacos herméticos limpos, fora do chão. Milho e amendoim húmidos criam bolores com aflatoxina, que é perigosa.',
    'ar': 'جفّف الحبوب جيدًا قبل التخزين: ينبغي أن تنكسر عند العض لا أن تنبعج. خزّنها في أكياس نظيفة محكمة ومرفوعة عن الأرض. الذرة والفول السوداني الرطبان ينمو عليهما عفن ينتج الأفلاتوكسين الضار.',
    'es': 'Seca bien el grano antes de guardarlo: debe quebrarse, no abollarse, al morderlo. Guárdalo en sacos herméticos limpios, sin tocar el suelo. El maíz y el maní húmedos crían mohos con aflatoxina, que es dañina.',
  }),
  Faq(['intercrop', 'mixed crop', 'cultures associées', 'kilimo mseto', 'consociação', 'زراعة بينية', 'تحميل', 'cultivos asociados', 'intercalar'], {
    'en': 'Intercropping is growing two crops together, such as maize with beans. The legume adds nitrogen and covers the soil, and if one crop fails the other still gives a harvest.',
    'fr': 'Les cultures associées consistent à cultiver deux plantes ensemble, comme le maïs et le haricot. La légumineuse apporte de l\'azote et couvre le sol, et si l\'une échoue l\'autre donne quand même.',
    'sw': 'Kilimo mseto ni kupanda mazao mawili pamoja, kama mahindi na maharagwe. Mikunde huongeza naitrojeni na kufunika udongo, na zao moja likishindwa jingine bado hutoa mavuno.',
    'pt': 'A consociação é cultivar duas culturas juntas, como milho com feijão. A leguminosa junta azoto e cobre o solo, e se uma falhar a outra ainda dá colheita.',
    'ar': 'الزراعة البينية هي زراعة محصولين معًا، مثل الذرة مع الفاصوليا. البقول تضيف النيتروجين وتغطي التربة، وإذا فشل محصول أعطى الآخر حصادًا.',
    'es': 'El cultivo asociado es sembrar dos cultivos juntos, como maíz con frijol. La leguminosa aporta nitrógeno y cubre el suelo, y si uno falla el otro aún da cosecha.',
  }),
  Faq(['fertilizer', 'fertiliser', 'engrais', 'mbolea ya', 'fertilizante', 'adubo químico', 'سماد كيميائي', 'أسمدة'], {
    'en': 'Fertilizer works best when it matches what the soil lacks, so test the soil first if you can. Apply small amounts close to the plant at planting and again at knee height, and combine it with manure or compost.',
    'fr': 'L\'engrais est plus efficace quand il correspond à ce qui manque au sol ; faites une analyse si possible. Apportez de petites doses près du plant au semis puis à hauteur de genou, avec du fumier ou du compost.',
    'sw': 'Mbolea hufanya kazi vizuri inapolingana na kinachokosekana udongoni, hivyo pima udongo kwanza ukiweza. Weka kiasi kidogo karibu na mmea wakati wa kupanda na tena mmea ukifika magotini, pamoja na samadi au mboji.',
    'pt': 'O adubo funciona melhor quando corresponde ao que falta no solo; faça uma análise se puder. Aplique pequenas doses junto à planta na sementeira e de novo à altura do joelho, com estrume ou composto.',
    'ar': 'السماد يعمل أفضل حين يطابق ما ينقص التربة، فحلّل التربة أولًا إن أمكن. أضف كميات صغيرة قرب النبات عند الزراعة ثم عند ارتفاع الركبة، مع السماد العضوي.',
    'es': 'El fertilizante funciona mejor cuando coincide con lo que le falta al suelo; analiza el suelo si puedes. Aplica dosis pequeñas junto a la planta al sembrar y otra vez a la altura de la rodilla, junto con estiércol o compost.',
  }),
  Faq(['ndvi', 'greenness', 'verdure', 'ukijani', 'verdura', 'اخضرار', 'verdor'], {
    'en': 'NDVI is a greenness score that satellites measure. About 0.1 to 0.2 is bare soil and 0.6 to 0.9 is dense, healthy crops. A drop below normal for the time of year means plants are under stress.',
    'fr': 'Le NDVI est un indice de verdure mesuré par satellite. Environ 0,1 à 0,2 correspond à un sol nu, 0,6 à 0,9 à des cultures denses et saines. Une baisse inhabituelle signale un stress des plantes.',
    'sw': 'NDVI ni kipimo cha ukijani kinachopimwa na setilaiti. Takriban 0.1 hadi 0.2 ni udongo wazi, 0.6 hadi 0.9 ni mazao mazito yenye afya. Kushuka chini ya kawaida huonyesha mimea ina shida.',
    'pt': 'O NDVI é um índice de verdura medido por satélite. Cerca de 0,1 a 0,2 é solo nu e 0,6 a 0,9 são culturas densas e saudáveis. Uma descida abaixo do normal indica plantas em stress.',
    'ar': 'مؤشر NDVI مقياس للاخضرار تقيسه الأقمار الصناعية. نحو 0.1 إلى 0.2 تربة عارية، و0.6 إلى 0.9 محاصيل كثيفة سليمة. انخفاضه عن المعتاد يعني أن النبات تحت إجهاد.',
    'es': 'El NDVI es un índice de verdor que miden los satélites. De 0,1 a 0,2 es suelo desnudo y de 0,6 a 0,9 cultivos densos y sanos. Una caída por debajo de lo normal indica plantas con estrés.',
  }),
  Faq(['weed', 'mauvaises herbes', 'magugu', 'ervas daninhas', 'أعشاب ضارة', 'حشائش', 'malezas', 'maleza'], {
    'en': 'Weed early: the first four to six weeks after planting matter most for yield. Mulch, close plant spacing and cover crops shade weeds out, and rotating crops stops any one weed from taking over.',
    'fr': 'Désherbez tôt : les quatre à six premières semaines après le semis comptent le plus. Paillage, semis serré et cultures de couverture étouffent les mauvaises herbes, et la rotation empêche qu\'une espèce domine.',
    'sw': 'Palilia mapema: wiki nne hadi sita za kwanza baada ya kupanda ndizo muhimu zaidi kwa mavuno. Matandazo, nafasi ndogo kati ya mimea na mazao ya kufunika hufunika magugu, na mzunguko huzuia gugu moja kutawala.',
    'pt': 'Sache cedo: as primeiras quatro a seis semanas após a sementeira contam mais. Cobertura morta, compasso apertado e culturas de cobertura abafam as ervas, e a rotação impede que uma espécie domine.',
    'ar': 'أزل الأعشاب مبكرًا: الأسابيع الأربعة إلى الستة الأولى بعد الزراعة هي الأهم للغلة. التغطية وتقريب المسافات ومحاصيل التغطية تخنق الأعشاب، والدورة تمنع سيطرة عشبة واحدة.',
    'es': 'Deshierba pronto: las primeras cuatro a seis semanas tras la siembra son las que más cuentan. El acolchado, la siembra densa y los cultivos de cobertura ahogan las malezas, y la rotación evita que una domine.',
  }),
];

/// The memorised answer that best fits [question], or null.
String? faqAnswer(String question) {
  final lower = ' ${question.toLowerCase()} ';
  Faq? best;
  var bestLen = 0;
  for (final f in faqs) {
    for (final k in f.keywords) {
      if (lower.contains(k) && k.length > bestLen) {
        best = f;
        bestLen = k.length;
      }
    }
  }
  return best == null ? null : (best.answers[Lang.code] ?? best.answers['en']);
}

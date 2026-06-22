# PraatGen — Complete Reference List (Corrected)

Extracted from the EML PraatGen Project Knowledge Base (v13.5), Master Prompt, and associated procedure libraries. All references cited or invoked in the codebase, command files, and appendices.

Verified against publisher databases 22 April 2026. 

---

## 1. Software and Primary Technical References

Boersma, P., & Weenink, D. (2024). *Praat: Doing phonetics by computer* (Version 6.4.62) [Computer software]. Institute of Phonetic Sciences, University of Amsterdam. https://www.fon.hum.uva.nl/praat/

- Praat manual: https://www.fon.hum.uva.nl/praat/manual/
- Praat source repository: https://github.com/praat/praat.github.io
- Special symbols reference: https://www.fon.hum.uva.nl/praat/manual/Special_symbols.html
- Functions reference: https://www.fon.hum.uva.nl/praat/manual/Functions.html

Howell, I. (2026). *EML PraatGen Scripting Assistant* (v13.5). Embodied Music Lab. https://www.embodiedmusiclab.com / https://github.com/embodied-music-lab/PraatGen

---

## 2. Electroglottography

Henrich, N., d'Alessandro, C., Doval, B., & Castellengo, M. (2004). On the use of the derivative of electroglottographic signals for characterization of nonpathological phonation. *Journal of the Acoustical Society of America*, *115*(3), 1321–1332. https://doi.org/10.1121/1.1646401
> Cited in: COMMANDS_Electroglottogram.txt §9. Referenced for first central difference DEGG method.

Herbst, C. T. (2020). Electroglottography – An update. *Journal of Voice*, *34*(4), 503–526. https://doi.org/10.1016/j.jvoice.2018.12.014
> Cited in: COMMANDS_Electroglottogram.txt §9. Referenced for caveat that GCI/GOI are inherently approximate.

Herbst, C. T., Fitch, W. T., & Švec, J. G. (2010). Electroglottographic wavegrams: A technique for visualizing vocal fold dynamics noninvasively. *Journal of the Acoustical Society of America*, *128*(5), 3070–3078. https://doi.org/10.1121/1.3493423
> Cited in: COMMANDS_Electroglottogram.txt §9. Referenced for DEGG analysis methodology.

Howard, D. M. (1995). Variation of electrolaryngographically derived closed quotient for trained and untrained adult female singers. *Journal of Voice*, *9*(2), 163–172. https://doi.org/10.1016/S0892-1997(05)80250-4
> Cited in: COMMANDS_Electroglottogram.txt §5, §9. Referenced for CQ25 threshold criterion.

---

## 3. Cepstral Analysis and Voice Quality (CPPS / AVQI)

Maryn, Y., & Weenink, D. (2015). Objective dysphonia measures in the program Praat: Smoothed cepstral peak prominence and acoustic voice quality index. *Journal of Voice*, *29*(1), 35–43. https://doi.org/10.1016/j.jvoice.2014.06.015
> Cited in: APPENDIX_D §5B, COMMANDS_PowerCepstrogram.txt, Master Prompt House Rules. Primary source for CPPS parameter set used throughout the PKB.

Maryn, Y., De Bodt, M., Barsties, B., & Roy, N. (2014). The value of the Acoustic Voice Quality Index as a measure of dysphonia severity in subjects speaking different languages. *European Archives of Oto-Rhino-Laryngology*, *271*, 1609–1619. https://doi.org/10.1007/s00405-013-2730-7
> Cited in: APPENDIX_D §10H. Source for AVQI v02.06 regression formula.

Maryn, Y., & Corthals, P. (2019). *Acoustic Voice Quality Index v.02.06* [Praat script]. Phonanium. https://www.phonanium.com/product/avqi/
> Cited in: APPENDIX_D §10. Script credits: Youri Maryn & Paul Corthals. Complete AVQI parameter specification extracted from this script.

Maryn, Y. (n.d.). *Phonanium Cepstrography v01.02* [Praat script]. Phonanium. https://www.phonanium.com/product/cepstrography/
> Cited in: APPENDIX_D §5B. Used to correct erratum on CPPS parameter defaults, 21 April 2026.

Watts, C. R., Awan, S. N., & Maryn, Y. (2017). A comparison of cepstral peak prominence measures from two acoustic analysis programs. *Journal of Voice*, *31*(3), 387.e1–387.e10. https://doi.org/10.1016/j.jvoice.2016.09.012
> Cited in: APPENDIX_D §5B. Corroborating source for Maryn & Weenink CPPS parameters in Praat.

Brockmann-Bauser, M., Van Stan, J. H., Carvalho Sampaio, M., Bohlender, J. E., Hillman, R. E., & Mehta, D. D. (2020). Effects of vocal intensity and fundamental frequency on cepstral peak prominence in patients with voice disorders and vocally healthy controls. *Journal of Voice*, *34*(5), 645–654. https://doi.org/10.1016/j.jvoice.2019.11.015
> Cited in: APPENDIX_D §5B. Corroborating source for CPPS parameter set.

Heller Murray, E. S., Chao, A., & Colletti, L. (2022). A practical guide to calculating cepstral peak prominence in Praat. *Journal of Voice*, *39*(2), 365–370. https://doi.org/10.1016/j.jvoice.2022.09.002
> Cited in: APPENDIX_D §5B. Corroborating source and Praat CPP plugin.

Murton, O., Hillman, R., & Mehta, D. (2020). Cepstral peak prominence values for clinical voice evaluation. *American Journal of Speech-Language Pathology*, *29*(3), 1596–1607. https://doi.org/10.1044/2020_AJSLP-20-00001
> Not directly cited by name in the PKB, but the primary clinical cutoff study for CPP using the same parameter set; part of the same literature ecosystem as the above entries.

---

## 4. Statistical Methods

Cohen, J. (1988). *Statistical power analysis for the behavioral sciences* (2nd ed.). Lawrence Erlbaum Associates.
> Referenced throughout EML_PROCEDURE_GUIDE.md §2.3 and eml-output.praat for effect size interpretation thresholds (d: small 0.2, medium 0.5, large 0.8).

Hays, W. L. (1988). *Statistics* (4th ed.). Holt, Rinehart and Winston.
> Cited in: eml-inferential.praat (@emlOneWayAnova). Source for the 12-step ANOVA computational formula.

Kerby, D. S. (2014). The simple difference formula: An approach to teaching nonparametric correlation. *Comprehensive Psychology*, *3*, 11.IT.3.1. https://doi.org/10.2466/11.IT.3.1 (SAGE-hosted full text: https://journals.sagepub.com/doi/full/10.2466/11.IT.3.1)
> Cited in: eml-inferential.praat (@emlMatchedPairsR, @emlRankBiserialR). Source for T-based matched-pairs rank-biserial r and the directed rank-biserial formula.

Rosenthal, R. (1991). *Meta-analytic procedures for social research* (Rev. ed.). Sage.
> Cited in: eml-inferential.praat (@emlMatchedPairsR). Source for Z-based r = z / √n effect size approximation.

Wendt, H. W. (1972). Dealing with a common problem in social science: A simplified rank-biserial coefficient of correlation based on the U statistic. *European Journal of Social Psychology*, *2*(4), 471–482. https://doi.org/10.1002/ejsp.2420020412
> Cited in: eml-inferential.praat (@emlRankBiserialR). Source for the directed rank-biserial correlation formula r = (U₁ − U₂) / (n₁ × n₂).

Tomczak, M., & Tomczak, E. (2014). The need to report effect size estimates revisited: An overview of some recommended measures of effect size. *Trends in Sport Sciences*, *1*(21), 19–25.
> Cited in: eml-inferential.praat (@emlEpsilonSquared). Source for epsilon-squared formula ε² = H / (N − 1) for Kruskal-Wallis.

Rea, L. M., & Parker, R. A. (2014). *Designing and conducting survey research: A comprehensive guide* (4th ed.). Jossey-Bass.
> Cited in: eml-inferential.praat (@emlEpsilonSquared). Source for epsilon-squared interpretive guidelines (< 0.01 negligible, 0.01–0.06 small, 0.06–0.14 medium, ≥ 0.14 large).

---

## 5. Built-in Praat Datasets (referenced via Table/TableOfReal creation commands)

Peterson, G. E., & Barney, H. L. (1952). Control methods used in a study of the vowels. *Journal of the Acoustical Society of America*, *24*(2), 175–184. https://doi.org/10.1121/1.1906875
> Invoked via: `Create formant table (Peterson & Barney 1952)` (COMMANDS_Table.txt, PRAAT_DEFINITIVE_CATALOGUE.txt).

Hillenbrand, J., Getty, L. A., Clark, M. J., & Wheeler, K. (1995). Acoustic characteristics of American English vowels. *Journal of the Acoustical Society of America*, *97*(5), 3099–3111. https://doi.org/10.1121/1.411872
> Invoked via: `Create formant table (Hillenbrand et al. 1995)` (PRAAT_DEFINITIVE_CATALOGUE.txt).

Pols, L. C. W., & Van Nierop, D. J. P. J. (1973). Frequency analysis of Dutch vowels from 50 male speakers. *Journal of the Acoustical Society of America*, *53*(4), 1093–1101. https://doi.org/10.1121/1.1913429
> Invoked via: `Create formant table (Pols & Van Nierop 1973)` (COMMANDS_Table.txt).

Weenink, D. (1985). *Formant data* [Dataset embedded in Praat].
> Invoked via: `Create formant table (Weenink 1985)` (COMMANDS_Table.txt).

Keating, P. A., & Esposito, C. (2006). Linguistic voice quality. *UCLA Working Papers in Phonetics*, *105*, 85–91.
> Invoked via: `Create H1H2 table (Keating & Esposito 2006)` (COMMANDS_Table.txt).

Ganong, W. F. (1980). Phonetic categorization in auditory word perception. *Journal of Experimental Psychology: Human Perception and Performance*, *6*(1), 110–125. https://doi.org/10.1037/0096-1523.6.1.110
> Invoked via: `Create Table (Ganong 1980)` (COMMANDS_Table.txt).

Sandwell, D. T. (1987). Biharmonic spline interpolation of GEOS-3 and SEASAT altimeter data. *Geophysical Research Letters*, *14*(2), 139–142. https://doi.org/10.1029/GL014i002p00139
> Invoked via: `Create TableOfReal (Sandwell 1987)` (COMMANDS_Table.txt).

---

## 6. Community Tools (EGG Analysis)

Kirby, J. (n.d.). *praatdet: Praat-based DEGG analysis tool* [Praat script]. https://github.com/kirbyj/praatdet
> Cited in: COMMANDS_Electroglottogram.txt §8. OQ measurement via DEGG peak detection with manual correction.

Chan, M. P. Y., et al. (2024). *PrEgg: Praat-based EGG analysis tool* [Praat script]. https://github.com/maypychan/praat-egg
> Cited in: COMMANDS_Electroglottogram.txt §8. Extracts CQ, Skew Quotient (SQ), and Peak Increase in Contact (PIC). JASA abstract.

Brunelle, M. (n.d.). *EGG_DEGG scripts* [Praat scripts]. NC State University.
> Cited in: COMMANDS_Electroglottogram.txt §8. Calculate DEGG from EGG channel, combine into stereo for visualization.

---

## Notes

1. **Praat manual URL convention:** All Praat manual URLs in the PKB follow the pattern `https://www.fon.hum.uva.nl/praat/manual/[ObjectType]__[Command_name]___.html` with spaces replaced by underscores and the URL ending in `___`. These are Tier 2 verification sources per Rule 12.

2. **PRAAT_DEFINITIVE_CATALOGUE.txt** was generated from Praat v6.4.62 C++ source code via automated parsing (20 March 2026). It is a derived work from the Praat source, not a separately published reference.

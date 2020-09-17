[@en]

# Digital Logic project: working zone encoder

This project is one of the three required to complete the bachelor degree in Engineering of Computing Systems at
Politecnico di Milano, as of A.Y. 2019/2020.

The assigned task consists in the realization of a synthesizable digital component which takes a 7-bit address as
input, and outputs an 8-bit working zone-encoded address. Initial configuration, inputs and outputs are
respectively supplied and provided through a simple RAM module, of which a reference implementation can be found in
the [Xilinx Vivado synthesis guide](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2017_3/ug901-vivado-synthesis.pdf).

## Memory layout summary

* Bytes 0-7: contain a configurable set of 8 working zones, 4 addresses wide each.
* Byte 8: contains the input address.
* Byte 9: is where the resulting address has to be written.

## Behaviour

After memorizing the working zones into appropriate internal registers, the input address is read and, if it
belongs to a working zone, the corresponding encoding is produced and written at the output address; otherwise it is
simply copied.

Once an encoding run is completed, the component can accept a new request without needing a reset nor a reload of
the working zones.

## Tests

With this repo come three simulation sources (under `RL1920.srcs/sim_1/`): one imported from the files handed out
by the professors (under `imports/Hardware`), one obtained by altering the input address value of the same test
bench (under `new/project_tb_alt.vhd`) and, finally, one (`new/unitest.vhd`) designed to load stimuli from an
external file, like the one named `electrosaint.pertini.txt` under the root's subdirectory `tests`.

### Fuzzing

This project includes a fuzzer, written in Python, that outputs stimuli readable by the `unitest` simulation
bench. You can find it under `tests/fuzzer.py`. It accepts a single argument: the number of encoding runs to produce.

## Documentation

Under the `doc` directory, you can find a compilable `doc.tex` file and its graphics files, plus a circuital
representation of the various components (`encoder.circ`, readable by [Logisim](http://www.cburch.com/logisim)) and
a state representation for the control unit (`machine_states.jff`, redable by [JFLAP](http://www.jflap.org)).

Unfortunately, this more in-depth report is only available in Italian (`it`).


[@it]

# Progetto di Reti Logiche: encoder di working zone

Questo progetto è uno dei tre richiesti per ottenere la laurea triennale in Ingegneria Informatica del Politecnico
di Milano, stando al regolamento dell'A.A. 2019/2020.

Il compito assegnato consiste nella realizzazione di un componente digitale sintetizzabile che, dato in input un
indirizzo di memoria da 7 bit, produca in output un indirizzo da 8 bit codificato secondo la codifica a
"working zones". La configurazione iniziale, gli input e gli output sono rispettivamente letti e scritti
attraverso un semplice modulo RAM, la cui implementazione di riferimento può essere reperita nella
[Xilinx Vivado synthesis guide](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2017_3/ug901-vivado-synthesis.pdf).

## Layout della memoria
* Byte 0-7: contengono un insieme configurabile di 8 working zone, ognuna grande 4 indirizzi.
* Byte 8: contiente l'indirizzo di input.
* Byte 9: è la locazione nella quale verrà scritto il risultato.

## Comportamento

Dopo aver memorizzato le working zone nei registri interni appropriati, l'indirizzo di input viene letto e, se esso
appartiene ad una working zone, il suo valore codificato viene calcolato e scritto all'indirizzo di output;
altrimenti, l'indirizzo in input viene semplicemente copiato.

Una volta completata una run di codifica, il componente può accettare una nuova richiesta senza bisogno di reset o di
un nuovo caricamento della configurazione iniziale.

## Test

Dentro questa repo si possono trovare tre sorgenti di simulazione (sotto `RL1920.srcs/sim_1/`): uno importato
direttamente dai file forniti dal corpo docente (sotto `imports/Hardware`), uno ottenuto modificando l'indirizzo in
input nel suddetto file (sotto `new/project_tb_alt.vhd`) e, infine, un sorgente (`new/unitest.vhd`) in grado di
leggere gli stimoli da un file esterno, scritto nel formato del file `electrosaint.pertini.txt` nella
sottodirectory di primo livello `tests`.

### Fuzzing

I file di progetto includono un fuzzer, scritto in Python, che si occupa di produrre stimoli leggibili da `unitest`.
Il programma si può trovare sotto `tests/fuzzer.py` ed accetta un solo argomento: il numeoro di run da produrre.

## Documentazione

Sotto la directory `doc` si trovano: un file `doc.tex` compilabile assieme ai suoi asset grafici, una
rappresentazione circuitale dei vari componenti (`encoder.circ`, leggibile da [Logisim](http://www.cburch.com/logisim))
e una rappresentazione degli stati dell'unità di controllo (`machine_states.jff`, leggibile da
[JFLAP](http://www.jflap.org)).

Il report prodotto compilando il file TeX contiene maggiori dettagli riguardo alle scelte progettuali,
all'organizzazione interna del componente e alle modalità di test.

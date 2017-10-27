# Market index for cryptocurrencies

Cryptocurrencies (like Bitcoin for example) have recently received much attention, with their prices gaining momentum lately. Joining a competition on the design of market indices for such currencies organized by [Lykke.com](https://streams.lykke.com/Project/ProjectDetails/join-lykke-in-launching-a-crypto-index), we propose the market index *Lykke Crypto Index 20* to be the weighted average of the 20 largest cryptocurrencies' market capitalization. The purpose of the index is to closely follow the value of cryptocurrencies, and to reflect both short-term movements and long-term trends.

We structured our project as follows:

- Our technical paper can be found in the directory *Paper/*.
- The analysis is done in the directories *Matlab/* and *R/*. In *Matlab/* we calculate the index and produce the paper figures. *R/* contains the code to download the data via the Rest API and other exercises to construct the index.
- In *Data/* we store our daily data sample as well as a data snapshot of all available currencies and their market capitalization as of September 22, 2017.

The research is conducted by [Onno Kleen](https://www.uni-heidelberg.de/fakultaeten/wiso/awi/professuren/empwirtfor/onnokleen.html) and [Christopher Zuber](http://www.uni-heidelberg.de/fakultaeten/wiso/awi/professuren/wipol/CvChristopherZuber.html).

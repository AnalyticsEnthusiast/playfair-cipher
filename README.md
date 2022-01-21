## Implementation of a playfair cipher in bourne again shell (/bin/bash)

**Author: Darren Foley**

**Creation Date: 2022-01-13**

------------------

### Script usage

1. First generate the keysquare with your 5 letter keyword. Default location for keysquare file is /tmp/keysquare.

```

> ./playfair_cipher.sh -G
Enter your cipher keyword below
Try to use a simple 5 letter word
Cipher Keyword:

```

2. Next encrypt your message. Unless specified the script looks for the default keysquare file at /tmp/keysquare.

```

> ./playfair_cipher.sh -e "SEND HELP NOW"
AS LG LO HR HA XY
ASLGL OHRHA XY

```

3. To decrypt your message pass it the back to the script. Again, the script looks at /tmp/keysquare for keysquare file. Example below uses the "-p" flag to explicitly use a different keysquare file.

```

> ./playfair_cipher.sh -d "ASLGL OHRHA XY" -p /tmp/keysquare
SENDHELPNOW

```
 
<br>

--------------------

### Introduction

<p>The playfair cipher is a symmetric encryption technique for obfuscating messages of text using digram substitution. It was originally developed by Charles Wheatstone but was popularised by Lord Playfair, hence the name.</p>

<br>

<p>The playfair cipher uses a 5X5 scrambled alphabet keysquare for encryption and decryption of text. It can handle letters only, not numbers, spaces or other ASCII characters such as '%' or '$'. The first 5 letters are from a randomly chosen 5 letter word followed by the remaining letters of the alphabet that have not been selected. I and J are merged in order for it to fit in a 5X5 square. </p>

```
N A M E S 
B C D F G 
H I K L O 
P Q R T U 
V W X Y Z
```

*Example keysquare*

<br>

<p>The data is encrypted by first seperating the string out into digrams like so:<p>

```
SEND HELP NOW
SE ND HE LP NO WX
```

<p>If there is a single letter left over at the end, insert a "null" character, typically an "X". If a duplicate digram is generated (e.g. "MM") then the second letter is replaced by the null character ("MX"). </p>

According to 

[tldp.org](https://tldp.org/LDP/abs/html/writingscripts.html)

For each digram, there are three possibilities.
-----------------------------------------------

1) Both letters will be on the same row of the key square:
   For each letter, substitute the one immediately to the right, in that
   row. If necessary, wrap around left to the beginning of the row.

or

2) Both letters will be in the same column of the key square:
   For each letter, substitute the one immediately below it, in that
   row. If necessary, wrap around to the top of the column.

or

3) Both letters will form the corners of a rectangle within the key square:
   For each letter, substitute the one on the other corner the rectangle
   which lies on the same row.

```

The "TH" digram falls under case #3.
H I K L
P Q R T

T --> L 
H --> P


The "SE" digram falls under case #1.
N A M E S     (Row containing "S" and "E")

S --> N  (wraps around left to beginning of row)
E --> S

```

Full output for the above example looks like this.

```
NS MB LN HT SH XY
```

The text is usually printed in groups of 5 letters like so.

```
NSMBL NHTSH XY
```

<br>

<p>In order to decrypt the above process is reversed to reveal the original plaintext message. </p>



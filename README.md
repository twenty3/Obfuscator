Obfuscator
==========

Simple Mac app that assists in generating C-code to include obfuscated secret keys and passwords in applications. The idea is to prevent easy analysis of the code binary with tools like 'strings' from yielding API keys, passwords and other strings that should stay confidential. 


Usage
=====

Enter an integer value for a and b (or click Random to generate one) and enter your string to obfuscate in the Secret field. Clicking 'Obfuscate' will then generate a C-language function that can be called with the same values of a and b that returns an NSString* with the secret.

Note that the obfuscation technique will not work with broad range of valid unicode characters. The only valid input strings will be single code-point characters in the range of 0x000 - 0xFFF. To be safe you should really only use standard roman alpha-numerics.


Attribution
===========

This tool was created originally while working on adding new functionality to The Magazine. The technique for obfuscation of the strings was devised by Marco. 
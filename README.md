# Forthress
A forth dialect prototype with its VM. 

***Can only be used under Linux X86-64***.

### Compile

```bash
nasm -f elf64 vm.asm -o vm.o && ld vm.o -o vm
```
### Run

```bash
./vm
```

### Concept

* **Native Word**: 

Word provided by the VM.

* **Colon Word**:

Word constituted by a series of Native Words (need ***docol*** to control the flow). 

Format: prologue: `xt_docol`, epilogue: `xt_ret`;

* **Control Flow**:

Execution Sequences (Native Words):

<pre>
+------+    +------+ 
| <i>word</i> | -> | <i>word</i> | ...
+------+    +------+
    ^           ^
    <i><b>w</b></i>           <i><b>pc</b></i>
</pre>


Execution Sequences (Colon Words):

<pre>
+------+    +------+ 
| <i><b>word</b></i> | -> | <i>word</i> | ...
+------+    +------+
    |           ^
    |           <i><b><s>pc (saved in rstack)</s></b></i>
+------+    +------+     |
| <i>word</i> | -> | <i>word</i> | ... |
+------+    +------+     | 
    ^           ^        |
    <i><b>w</b></i>           <i><b>pc (new position)</b></i> 
</pre>



### Architecture

* **Word**:

<pre>
|------------->  <i><b>header</b></i> (exclude private word)  <---------------|
+----------------------------+----------------+-----------------+------------------------+
| <i><b>addr</b> of previous word (dq)</i> | <i><b>label</b> (string)</i> | <i>(reserved byte)</i> | <i><b>addr</b> of implementation</i> |
+----------------------------+----------------+-----------------+------------------------+
</pre>

* **Dictionary**:

<pre>
        +------+    +------+     +------+    +------+
(tail)  | <i>word</i> | -> | <i>word</i> | ... | <i>word</i> | -> | <i>word</i> | (head)
        +------+    +------+     +------+    +------+
</pre>

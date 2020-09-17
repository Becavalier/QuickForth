
# QuickForth
A forth dialect prototype with its VM. 

***Can only be used under Linux X86-64***.

### Compile & Run

```bash
bash ./build.sh
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
|--------------------->  <i><b>header</b> (exclude private word)</i>  <-----------------------|
+-------------------------+----------------+-----------------+-----------------+---------------------+
| <i>previous word <b>addr</b> (dq)</i> | <i><b>label</b> (string)</i> | <i>(reserved byte)</i> | <i><b>immediates</b> (dq)</i> | <i>implementation <b>addr</b></i> |
+-------------------------+----------------+-----------------+-----------------+---------------------+

    +-----------------+
... | <i><b>immediates</b> (dq)</i> | ... => <i>(2 immdeiates at most, each one is 4 bytes.)</i>
    +-----------------+

</pre>

* **Dictionary**:

<pre>
 <i><b>(head)</b></i>                               <i><b>(tail)</b></i>             <i><b>(.bss)</b></i>
+------+    +------+     +------+    +------+    +--------------------+
| <i>word</i> | -> | <i>word</i> | ... | <i>word</i> | -> | <i>word</i> | -> | <i><b>dynamic_colon_stub</b></i> | -> <i>(dynamic words)</i>
+------+    +------+     +------+    +------+    +--------------------+

    +--------------------+        +-------------------------------------+
... | <i><b>dynamic_colon_stub</b></i> | ... => | <i>next effective address (dq)</i> | <i>words</i> | ... 
    +--------------------+        +-------------------------------------+

</pre>

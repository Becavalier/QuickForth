
# QuickForth
A simple forth dialect prototype with its VM, just for experimental purpose. 

\* *You can continue to extend the function of this VM if you will.*

***Can only be used under Linux X86-64***.

### Compile

```bash
make  # the binary will be compiled into the "build" folder.
```

### Modes

* **REPL**:

```bash
➜  Forthress git:(master) ✗ ./build/vm
> 1
> 2
> +
> .S
3
> exit
```

* **Interpreter**:

```bash
➜  Forthress git:(master) ✗ ./build/vm forth_discr.fth
-8
```

### Concepts

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
|---------------------->  <i><b>header</b> (exclude private word)</i>  <---------------------|
+---------------------+----------------+-----------------+---------------------+
| <i>next word <b>addr</b> (dq)</i> | <i><b>label</b> (string)</i> | <i>(reserved byte)</i> | <i>implementation <b>addr</b></i> |
+---------------------+----------------+-----------------+---------------------+
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
                                                  |--------------|--------^
</pre>

* **Opcode** *(For inner interpreter, saving the operation and immediates of each dynamic colon word)*:

<pre>
+----------------+-------------------+
| <i><b>opcode</b> (qword)</i> | <i><b>immediate</b> (qword)</i> |
+----------------+-------------------+
</pre>

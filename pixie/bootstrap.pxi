;; This file is used to build what we need to even start running stdlib.pxi
;; Ordering of stuff will probably matter here

(defprotocol ISeq
  (-first [this])
  (-next [this]))

(defprotocol ISeqable
  (-seq [this]))

(defprotocol ICounted
  (-count [this]))

(defprotocol IIndexed
  (-nth [this idx])
  (-nth-not-found [this idx not-found]))


(defprotocol IPersistentCollection
  (-conj [this x])
  (-disj [this x]))

(defprotocol IEmpty
  (-empty [this]))

(defprotocol IObject
  (-hash [this])
  (-eq [this other])
  (-str [this sbf])
  (-repr [this sbf]))

(defprotocol IReduce
  (-reduce [this f init]))

(defprotocol IDeref
  (-deref [this]))

(defprotocol IReset
  (-reset! [this val]))

(defprotocol INamed
  (-namespace [this])
  (-name [this]))

(defprotocol IAssociative
  (-assoc [this k v])
  (-contains-key [this k])
  (-dissoc [this k]))

(defprotocol ILookup
  (-val-at [this]))

(defprotocol IMapEntry
  (-key [this])
  (-val [this]))

(defprotocol IStack
  (-push [this v]))

(defprotocol IPop
  (-pop [this]))

(defprotocol IFn
  (-invoke [this args]))

(defprotocol IDoc
  (-doc [this]))

(defprotocol IVector)
(defprotocol ISequential)
(defprotocol IMap)

(defprotocol IMeta
  (-with-meta [this x])
  (-meta [this]))

(defprotocol ITransientCollection
  (-conj! [this x]))

(defprotocol IToTransient
  (-transient [this x]))

(defprotocol ITransient
  (-persistent! [this]))

(defprotocol ITransientStack
  (-push! [this x])
  (-pop! [this]))

(defprotocol IDisposable
  (-dispose! [this]))

(defprotocol IMessageObject
  (-get-field [this name])
  (-invoke-method [this name args]))


(defprotocol IEffect
  (-effect-val [this v])
  (-effect-return [this v]))

(-run-external-extends)

(extend -get-field Object -internal-get-field)


(extend-type Object
  (-str [x sb]
    (sb (-internal-to-str x)))
  
  (-repr  [x sb]
    (sb (-internal-to-repr x)))

  (-eq [this other]
    false))

(extend-type String
  IObject
  (-str [this sb]
    (sb this)))

;; Math wrappers

(extend -eq Number -num-eq)

(defn +
  {:doc "Adds the arguments, returning 0 if no arguments"
   :signatures [[& args]]
   :added "0.1"}  
  ([] 0)
  ([x] x)
  ([x y] (-add x y))
  ([x y & more]
   (-apply + (+ x y) more)))

(defn -
  ([] 0)
  ([x] x)
  ([x y] (-sub x y))
  ([x y & more]
   (-apply - (- x y) more)))

(defn *
  ([] 1)
  ([x] x)
  ([x y] (-mul x y))
  ([x y & args]
      (reduce -mul (-mul x y) args)))

(defn /
  ([x] (-div 1 x))
  ([x y] (-div x y))
  ([x y & args]
      (reduce -div (-div x y) args)))

(defn inc
  ([x] (+ x 1)))

(defn dec
  ([x] (- x 1)))

(defn <
  ([x y] (-lt x y))
  ([x y & more]
   (-apply < (< x y) more)))

(defn >
  ([x y] (-gt x y))
  ([x y & more]
   (-apply > (> x y) more)))


(defn <=
  ([x] true)
  ([x y] (-lte x y))
  ([x y & rest] (if (-lte x y)
                  (apply <= y rest)
                  false)))

(defn >=
  ([x] true)
  ([x y] (-gte x y))
  ([x y & rest] (if (-gte x y)
                  (apply >= y rest)
                  false)))


(defn =
  {:doc "Returns true if all the arguments are equivalent. Otherwise, returns false. Uses
-eq to perform equality checks."
   :signatures [[& args]]
   :added "0.1"}
  ([x] true)
  ([x y] (if (identical? x y)
           true
           (-eq x y)))
  ([x y & rest] (if (eq x y)
                  (apply = y rest)
                  false)))

(defn pos?
  {:doc "Returns true if x is greater than zero"
   :signatures [[x]]
   :added "0.1"}
  [x]
  (> x 0))

(defn neg?
  {:doc "Returns true if x is less than zero"
   :signatures [[x]]
   :added "0.1"}
  [x]
  (< x 0))

(defn zero?
  {:doc "Returns true if x is equal to zero"
   :signatures [[x]]
   :added "0.1"}
  [x]
  (= x 0))


;; Base functions

(defn hash
  [this]
  (-hash this))

(defn identity
  ^{:doc "The identity function. Returns its argument."
        :added "0.1"}
  ([x & _] x))

(defn not
  [x]
  (if x false true))

(defn not=
  ([& args]
   (not (-apply = args))))

(defn nil?
  [x]
  (identical? x nil))

(defn conj
  {:doc "Adds elements to the transient collection. Elements are added to the end except in the case of Cons lists"
   :signatures [[] [coll] [coll item] [coll item & args]]
   :added "0.1"}
  ([] [])
  ([coll] coll)
  ([coll itm] (-conj coll itm))
  ([coll item & more]
   (-apply conj (conj x y) more)))


(defn conj!
  {:doc "Adds elements to the transient collection. Elements are added to the end except in the case of Cons lists"
   :signatures [[] [coll] [coll item] [coll item & args]]
   :added "0.1"}
  ([] (-transient []))
  ([coll] (-persistent! coll))
  ([coll item] (-conj! coll item))
  ([coll item & args]
   (reduce -conj! (-conj! coll item) args)))

(defn disj
  {:doc "Removes elements from the collection."
   :signatures [[] [coll] [coll item]]
   :added "0.1"}
  ([] [])
  ([coll] coll)
  ([coll item] (-disj coll item))
  ([coll item & items]
   (reduce -disj (-disj coll item) items)))

(defn pop
  {:doc "Pops elements off a stack."
   :signatures [[] [coll] [coll item] [coll item & args]]
   :added "0.1"}
  ([] [])
  ([coll] (-pop coll)))

(defn push
  {:doc "Push an element on to a stack."
   :signatures [[] [coll] [coll item] [coll item & args]]
   :added "0.1"}
  ([coll x] (-push coll x)))

(defn pop!
  {:doc "Pops elements off a transient stack."
   :signatures [[] [coll] [coll item] [coll item & args]]
   :added "0.1"}
  ([coll] (-pop! coll)))

(defn push!
  {:doc "Push an element on to a transient stack."
   :signatures [[] [coll] [coll item] [coll item & args]]
   :added "0.1"}
  ([coll x] (-push! coll x)))


(defn nth
  {:doc "Returns the element at the idx.  If the index is not found it will return an error.
         However, if you specify a not-found parameter, it will substitute that instead"
   :signatures [[coll idx] [coll idx not-found]]
   :added "0.1"}
  ([coll idx] (-nth coll idx))
  ([coll idx not-found] (-nth-not-found coll idx not-found)))

(defn name
  [x] (-name x))

(defn namespace
  [x] (-namespace x))


(defn dispose!
  "Finalizes use of the object by cleaning up resources used by the object"
  [x]
  (-dispose! x)
  nil)


(defn has-meta?
  [x]
  (satisfies? IMeta x))

(defn meta
  [x]
  (-meta x))

(defn with-meta
  [x m]
  (-with-meta x m))

(defn count
  ([coll] (-count coll)))

(defn assoc
  {:doc "Associates the key with the value in the collection"
   :signatures [[m] [m k v] [m k v & kvs]]
   :added "0.1"}
  ([m] m)
  ([m k v]
     (-assoc m k v))
  ([m k v & rest]
     (apply assoc (-assoc m k v) rest)))

(defn key [m]
  (-key m))

(defn val [m]
  (-val m))

(defn seq [x]
  (-seq x))

(defn first [x]
  (-first (seq x)))

(defn next [x]
  (-next (seq x)))

(defn apply [f & args]
  (let [last-itm (last args)
        but-last-cnt (dec (count args))
        arg-array (make-array (+ but-last-cnt
                                 (count last-itm)))
        _ (array-copy args 0 arg-array 0 but-last-cnt)
        idx (reduce
             (fn [idx itm]
               (aset arg-array idx itm)
               (inc idx))
             but-last-cnt
             last-itm)]
    (-apply f arg-array)))

(defn last [coll]
  (if (vector? coll)
    (nth coll (dec (count coll)))
    (loop [coll coll]
      (if-let [v (next coll)]
        v
        (first coll)))))

(defn butlast [coll]
  (loop [res []
         coll coll]
    (if (next coll)
      (recur (conj res (first coll))
             (next coll))
      (seq res))))

;; Cons and List

(deftype Cons [first next meta]
  ISeq
  (-first [this] first)
  (-next [this] next)
  ISeqable
  (-seq [this] this)
  IMeta
  (-meta [this] meta)
  (-with-meta [this new-meta]
    (->Cons first next new-meta)))

(defn cons [head tail]
  (->Cons head (seq tail) nil))


(deftype List [head tail cnt hash-val meta]
  IObject
  (-hash [this]
    (if hash-val
      hash-val
      (let [val (reduce
                 pixie.stdlib.hashing/ordered-hashing-rf
                 this)]
        (set-field! this :hash-val val)
        val)))

  (-str [this sb]
    (sb "(")
    (let [not-first (atom false)]
      (reduce
       (fn [_ x]
         (if @not-first
           (sb " ")
           (reset! not-first true))
         (-str x sb))
       nil
       this))
    (sb ")"))

  IReduce
  (-reduce [this f init]
    (loop [acc init
           s this]
      (if (reduced? acc)
        @acc
        (if (nil? s)
          acc
          (recur (f acc (first s))
                 (next s))))))

  
  ISeq
  (-first [this] head)
  (-next [this] tail)

  ICounted
  (-count [this] cnt)

  ISeqable
  (-seq [this] this)

  IMeta
  (-meta [this] meta)
  (-with-meta [this new-meta]
    (->List head tail cnt hash-val meta))

  IPersistentCollection
  (-conj [this val]
    (->List val this (inc cnt) nil nil)))


(defn list [& args]
  (loop [acc nil
         idx (dec (count args))
         cnt 0]
    (if (>= idx 0)
      (recur (->List (nth args idx)
                     acc
                     cnt
                     nil
                     nil)
             (dec idx)
             (inc cnt))
      acc)))


;; String Builder

(defn string-builder
  ([] (-string-builder))
  ([sb] (-internal-to-str sb))
  ([sb x]
   (if (instance? String x)
     (-add-to-string-builder sb x)
     (-str x (fn [x]
               (-add-to-string-builder sb x))))))

(defn str
  [& args]
  (reduce
   string-builder
   args))



(defn println [& args]
  (let [sb (-string-builder)
        add-fn (fn [x]
                 (-add-to-string-builder sb x))]
    (loop [idx 0
           sb sb]
      (if (< idx (count args))
        (recur (inc idx)
               (do (-str (aget args idx) add-fn)
                   (add-fn " ")
                 sb))
        (-blocking-println (-finish-string-builder sb))))
    nil))

;;

;; Hashing Functions

(in-ns :pixie.stdlib.hashing)


(def seed 0)
(def C1 (size-t 0xcc9e2d51))
(def C2 (size-t 0x1b873593))
(def LONG-BIT (size-t 32))
(def MASK-32 (size-t 0xFFFFFFFF))

(defn mask-32 [x]
  (bit-and x MASK-32))

(defn rotr [value shift]
  (let [value (size-t value)
        shift (size-t shift)]
    (bit-or (bit-shift-left value shift)
            (bit-shift-right value (- LONG-BIT shift)))))

(defn rotl [value shift]
  (let [value (size-t value)
        shift (size-t shift)]
    (bit-or (bit-shift-right value shift)
            (bit-shift-left value (- LONG-BIT shift)))))

(defn mix-k1 [k1]
  (let [k1 (* k1 C1)
        k1 (rotl k1 15)
        k1 (* k1 C2)]
    k1))

(defn mix-h1 [h1 k1]
  (let [h1 (bit-xor h1 k1)
        h1 (rotr h1 13)
        h1 (+ (* h1 5) 0xe6546b64)]
    h1))


(defn fmix [h1 length]
  (let [h1 (bit-xor h1 length)
        h1 (bit-xor h1 (bit-shift-right h1 16))
        h1 (* h1 0x85ebca6b)
        h1 (bit-xor h1 (bit-shift-right h1 13))
        h1 (* h1 0xc2b2ae35)
        h1 (bit-xor h1 (bit-shift-right h1 16))]
    h1))


(defn mix-coll-hash [hash count]
  (let [h1 seed
        k1 (mix-k1 hash)
        h1 (mix-h1 h1 k1)]
    (fmix h1 count)))

(deftype HashingState [n hash]
  IMessageObject
  (-get-field [this field]
    (get-field this field)))

(defn unordered-hashing-rf
  ([] (->HashingState (size-t 0) (size-t 1)))
  ([acc]
   (mix-coll-hash (.-hash acc)
                  (.-n acc)))
  ([acc itm]
   (set-field! acc :n (inc (.-n acc)))
   (set-field! acc :hash (+ (.-hash acc)
                            (hash itm)))))

(defn ordered-hashing-rf
  ([] (->HashingState 0 1))
  ([acc]
   (mix-coll-hash (.-hash acc)
                  (.-n acc)))
  ([acc itm]
   (set-field! acc :n (inc (.-n acc)))
   (set-field! acc :hash (+ (* (size-t 31) (.-hash acc))
                            (hash itm)))))



(defn hash-int [input]
  (if (= input 0)
    0
    (let [k1 (mix-k1 input)
          h1 (mix-h1 seed k1)]
      (fmix h1 4))))

(defn hash-unencoded-chars [u]
  (let [h1 (loop [i 1
                  h1 seed]
             (if (< i (count u))
               (let [k1 (bit-or (int (nth u (dec i)))
                                (bit-shift-left (int (nth u i)) 16))
                     k1 (mix-k1 k1)
                     h1 (mix-h1 h1 k1)]
                 (recur (+ 2 i)
                        h1))
               h1))
        h1 (if (= (bit-and (count u) 1) 1)
             (let [k1 (int (nth u (dec (count u))))
                   k1 (mix-k1 k1)
                   h1 (bit-xor h1 k1)]
               h1)
             h1)]
    (fmix h1 (* 2 (count u)))))

(in-ns :pixie.stdlib)

;; End Hashing Functions


;; Reduced

(deftype Reduced [x]
  IDeref
  (-deref [this] x))

(defn reduced [x]
  (->Reduced x))

(defn reduced? [x]
  (instance? Reduced x))

;; End Reduced

;; Basic Transducer Support

(defn transduce
  ([f coll]
   (let [result (-reduce coll f (f))]
     (f result)))
  ([xform rf coll]
   (let [f (xform rf)
         result (-reduce coll f (f))]
     (f result)))
  ([xform rf init coll]
   (let [f (xform rf)
         result (-reduce coll f init)]
     (f result))))

(defn reduce 
  ([rf col]
   (rf (reduce rf (rf) col)))
  ([rf init col]
   (-reduce col rf init)))

(defn into
  ^{:doc "Add the elements of `from` to the collection `to`."
    :signatures [[to from]]
    :added "0.1"}
  ([to from]
   (if (satisfies? IToTransient to)
     (persistent! (reduce conj! (transient to) from))
     (reduce conj to from)))
  ([to xform from]
   (if (satisfies? IToTransient to)
     (transduce xform conj! (transient to) from)
     (transduce xform conj to from))))

(defn map
  ^{:doc "map - creates a transducer that applies f to every input element"
    :signatures [[f] [f coll]]
    :added "0.1"}
  ([f]
   (fn [xf]
     (fn
       ([] (xf))
       ([result] (xf result))
       ([result item] (xf result (f item))))))
  ([f coll]
   (lazy-seq*
    (fn []
      (let [s (seq coll)]
        (if s
          (cons (f (first s))
                (map f (rest s)))
          nil)))))
  ([f & colls]
   (let [step (fn step [cs]
                (lazy-seq*
                 (fn []
                   (let [ss (map seq cs)]
                     (if (every? identity ss)
                       (cons (map first ss) (step (map rest ss)))
                       nil)))))]
     (map (fn [args] (apply f args)) (step colls)))))


(defn interpose
  ^{:doc "Returns a transducer that inserts `val` in between elements of a collection."
    :signatures [[val] [val coll]]
    :added "0.1"}
  ([val] (fn [xf]
           (let [first? (atom true)]
             (fn
               ([] (xf))
               ([result] (xf result))
               ([result item] (if @first?
                                (do (reset! first? false)
                                    (xf result item))
                                (xf (xf result val) item)))))))
  ([val coll]
   (transduce (interpose val) conj coll)))


(def preserving-reduced
  (fn preserving-reduced [rf]
    (fn pr-inner [a b]
      (let [ret (rf a b)]
        (if (reduced? ret)
          (reduced ret)
          ret)))))

(defn cat
  {:doc "A transducer that concatenates elements of a collection."
   :added "0.1"}
  [rf]
  (let [rrf (preserving-reduced rf)]
    (fn cat-inner
      ([] (rf))
      ([result] (rf result))
      ([result input]
       (reduce rrf result input)))))

(defn mapcat
  {:doc "Maps f over the elements of coll and concatenates the result"
   :added "0.1"}
  ([f]
   (comp (map f) cat))
  ([f coll]
   (transduce (mapcat f) conj coll)))


;; End Basic Transudcer Support

;; Type Checks

(defn instance?
  {:doc "Checks if x is an instance of t.

                           When t is seqable, checks if x is an instance of
                           any of the types contained therein."
   :signatures [[t x]]}
  [t x]
  (if (-satisfies? ISeqable t)
    (let [ts (seq t)]
      (if (not ts) false
          (if (-instance? (first ts) x)
            true
            (instance? (rest ts) x))))
    (-instance? t x)))

(defn satisfies?
  ^{:doc "Checks if x satisfies the protocol p.

                            When p is seqable, checks if x satisfies all of
                            the protocols contained therein."
    :signatures [[t x]]}
  [p x]  
  (if (-satisfies? ISeqable p)
    (let [ps (seq p)]
      (if (not ps) true
          (if (not (-satisfies? (first ps) x))
            false
            (satisfies? (rest ps) x))))
    (-satisfies? p x)))


(defn true? [v] (identical? v true))
(defn false? [v] (identical? v false))

(defn number? [v] (instance? Number v))
(defn integer? [v] (instance? Integer v))
(defn float? [v] (instance? Float v))
(defn ratio? [v] (instance? Ratio v))

(defn char? [v] (instance? Character v))
(defn string? [v] (instance? String v))
(defn symbol? [v] (instance? Symbol v))
(defn keyword? [v] (instance? Keyword v))

(defn list? [v] (instance? [PersistentList Cons] v))
(defn seq? [v] (satisfies? ISeq v))
(defn set? [v] (instance? PersistentHashSet v))
(defn map? [v] (satisfies? IMap v))
(defn fn? [v] (satisfies? IFn v))

(defn indexed? [v] (satisfies? IIndexed v))
(defn counted? [v] (satisfies? ICounted v))
(defn vector? [v] (satisfies? IVector v))

(defn int
  {:doc "Converts a number to an integer."
   :since "0.1"}
  [x]
  (cond
   (integer? x) x
   (float? x) (lround (floor x))
   (ratio? x) (int (/ (float (numerator x)) (float (denominator x))))
   (char? x) (-internal-int x)
   :else (throw
          [:pixie.stdlib/ConversionException
           (throw (str "Can't convert a value of type " (type x) " to an Integer"))])))


;; End Type Checks

;; Range

(in-ns :pixie.stdlib.range)

(deftype Range [start stop step]
  IReduce
  (-reduce [self f init]
    (loop [i start
           acc init]
      (if (or (and (> step 0) (< i stop))
              (and (< step 0) (> i stop))
              (and (= step 0)))
        (let [acc (f acc i)]
          (if (reduced? acc)
            @acc
            (recur (+ i step) acc)))
        acc)))
  ICounted
  (-count [self]
    (if (or (and (< start stop) (< step 0))
            (and (> start stop) (> step 0))
            (= step 0))
      0
      (abs (quot (- start stop) step))))
  IIndexed
  (-nth [self idx]
    (when (or (= start stop 0) (neg? idx))
      (throw [:pixie.stdlib/OutOfRangeException "Index out of Range"]))
    (let [cmp (if (< start stop) < >)
          val (+ start (* idx step))]
      (if (cmp val stop)
        val
        (throw [:pixie.stdlib/OutOfRangeException "Index out of Range"]))))
  (-nth-not-found [self idx not-found]
    (let [cmp (if (< start stop) < >)
          val (+ start (* idx step))]
      (if (cmp val stop)
        val
       not-found)))
  ISeqable
  (-seq [self]
    (when (or (and (> step 0) (< start stop))
              (and (< step 0) (> start stop)))
      (cons start (lazy-seq* #(range (+ start step) stop step)))))
  IObject
  (-str [this sbf]
    (-str (seq this) sbf))
  (-repr [this sbf]
    (-repr (seq this) sbf))
  (-eq [this sb]
    nil))

(def MAX-NUMBER 0xFFFFFFFF) ;; 32 bits ought to be enough for anyone ;-)

(in-ns :pixie.stdlib)

(defn range
  {:doc "Returns a range of numbers."
   :examples [["(seq (range 3))" nil (0 1 2)]
              ["(seq (range 3 5))" nil (3 4)]
              ["(seq (range 0 10 2))" nil (0 2 4 6 8)]
              ["(seq (range 5 -1 -1))" nil (5 4 3 2 1 0)]]
   :signatures [[] [stop] [start stop] [start stop step]]
   :added "0.1"}
  ([] (pixie.stdlib.range/->Range 0 MAX-NUMBER 1))
  ([stop] (pixie.stdlib.range/->Range 0 stop 1))
  ([start stop] (pixie.stdlib.range/->Range start stop 1))
  ([start stop step] (pixie.stdlib.range/->Range start stop step)))

;; End Range

(in-ns :pixie.stdlib)

;; Extend String

(extend-type String
  IIndexed
  (-nth [self idx]
    (-str-nth self idx))

  ICounted
  (-count [self]
    (-str-len self))

  IReduce
  (-reduce [self f init]
    (loop [acc init
           idx 0]
      (if (< idx (count self))
        (if (reduced? acc)
          @acc
          (recur (f acc (nth self idx))
                 (inc idx)))
        acc))))

;; End Extend String

;; Extend Array

(satisfy IVector Array)

(extend-type Array
  IPersistentCollection
  (-conj [arr itm]
    (conj (pixie.stdlib.persistent-vector/vector-from-array arr) itm))

  IIndexed
  (-nth [this idx]
    (if (and (<= 0 idx)
             (< idx (count this)))
      (aget this idx)
      (throw [:pixie.stdlib/IndexOutOfRangeException
              "Index out of range"])))
  (-nth-not-found [this idx not-found]
    (if (and (<= 0 idx)
             (< idx (count this)))
      (aget this idx)
      not-found))
  
  ICounted
  (-count ([arr]
           (.-count arr)))

  IReduce
  (-reduce [this f init]
    (loop [idx 0
           acc init]
      (if (reduced? acc)
        @acc
        (if (< idx (count this))
          (recur (inc idx)
                 (f acc (aget this idx)))
          acc)))))

(defn array-copy [from from-idx to to-idx size]
  (loop [idx 0]
    (when (< idx size)
      (do (aset to (+ to-idx idx) (aget from (+ from-idx idx)))
          (recur (inc idx))))))

(defn array-append [arr val]
  (let [new-array (make-array (inc (count arr)))]
    (array-copy arr 0 new-array 0 (count arr))
    (aset new-array (count arr) val)
    new-array))

(defn array-clone [arr]
  (let [new-array (make-array (count arr))]
    (array-copy arr 0 new-array 0 (count arr))
    new-array))

(defn array-resize [arr size]
  (let [new-array (make-array size)]
    (array-copy arr 0 new-array 0 size)
    new-array))

;;;

;; Atom

(defprotocol IAtom
  (-swap! [this f args])
  (-reset! [this val]))

(deftype Atom [value]
  IDeref
  (-deref [this]
    value)

  IAtom
  (-swap! [this f args]
    (-reset! this (apply f @this args)))
  (-reset! [this val]
    (set-field! this :value val)))

(defn atom [init]
  (->Atom init))

(defn swap! [a f & args]
  (-swap! a f args))

(defn reset! [a v]
  (-reset! a v))

;; End Atom

;; Map Entry



(deftype MapEntry [k v meta]
  IMapEntry
  (-key [this]
    k)
  (-val [this]
    v)
  
  IIndexed
  (-nth [this idx]
    (cond
      (= idx 0) k
      (= idx 1) v
      :else (throw [:pixie.stdlib/IndexError
                    "Index out of Range"])))
  
  (-nth-not-found [this idx not-found]
    (cond
      (= idx 0) k
      (= idx 1) v
      :else not-found)))

(defn map-entry [k v]
  (->MapEntry k v nil))

;; End Map Entry


;; PersistentVector

(in-ns :pixie.stdlib.persistent-vector)

(deftype Node [edit array]
  IMessageObject
  (-get-field [this name]
    (get-field this name)))

(defn new-node
  ([edit]
   (new-node edit (make-array 32)))
  ([edit array]
   (->Node edit array)))

(def EMPTY-NODE (new-node nil))



(defn tailoff [this]
  (let [cnt (.-cnt this)]
    (if (< cnt 32)
      0
      (bit-shift-left (bit-shift-right (dec cnt) 5) 5))))

(defn array-for [this i]
  (if (and (<= 0 i) (< i (.-cnt this)))
    (if (>= i (tailoff this))
      (.-tail this)
      (loop [node (.-root this)
             level (.-shift this)]
        (if (> level 0)
          (recur (aget (.-array node)
                       (bit-and (bit-shift-right i level) 0x01f))
                 (- level 5))
          (.-array node))))
    (throw [:pixie.stdlib/IndexOutOfRangeException
            "Index out of range"])))

(deftype PersistentVector [cnt shift root tail hash-val meta]
  IObject
  (-hash [this]
    (if hash-val
      hash-val
      (let [val (reduce
                 pixie.stdlib.hashing/ordered-hashing-rf
                 this)]
        (set-field! this :hash-val val)
        val)))

  (-str [this sb]
    (sb "[")
    (let [not-first (atom false)]
      (reduce
       (fn [_ x]
         (if @not-first
           (sb " ")
           (reset! not-first true))
         (-str x sb))
       nil
       this))
    (sb "]"))  
  
  
  IMessageObject
  (-get-field [this name]
    (get-field this name))
  
  IPersistentCollection
  (-conj [this val]
    (assert (< cnt 0xFFFFFFFF) "Vector too large")

    (if (< (- cnt (tailoff this)) 32)
      (let [new-tail (array-append tail val)]
        (->PersistentVector (inc cnt) shift root new-tail hash-val meta))
      
      (let [tail-node (->Node (.-edit root) tail)]
        (if (> (bit-shift-right cnt 5) (bit-shift-left 1 shift))

          (let [new-root (new-node (.-edit root))
                new-root-arr (.-array new-root)]
            (aset new-root-arr 0 root)
            (aset new-root-arr 1 (new-path (.-edit root) shift tail-node))
            (->PersistentVector (inc cnt)
                                (+ shift 5)
                                new-root
                                (array val)
                                hash-val
                                meta))
          (let [new-root (push-tail this shift root tail-node)]
            (->PersistentVector (inc cnt)
                                shift
                                new-root
                                (array val)
                                hash-val
                                meta))))))
  IIndexed
  (-nth [self i]
    (if (and (<= 0 i)
             (< i cnt))
      (let [node (array-for self i)]
        (aget node (bit-and i 0x01F)))
      (throw [:pixie.stdlib/IndexOutOfRange
              (str "Index out of range, got " i " only have " cnt)])))
  
  (-nth-not-found [self i not-found]
    (if (and (<= 0 i)
             (< i cnt))
      (let [node (array-for self i)]
        (aget node (bit-and i 0x01F)))
      not-found))

  

  ILookup
  (-val-at [this val]
    (-nth-not-found self val nil))
  

  ICounted
  (-count [this] cnt)

  IPop
  (-pop [this]
    (assert (not= cnt 0) "Can't pop an empty vector")

    (if (= cnt 1)
      EMPTY
      (if (> (- cnt (tailoff this)) 1)
        (let [size (dec (count tail))
              new-tail (array-resize tail size)]
          (->PersistentVector (dec cnt)
                              shift
                              root
                              new-tail
                              hash-val
                              meta))
        (let [new-tail (array-for this (- cnt 2))
              new-root (pop-tail this shift root)]
          (cond
            (nil? new-root)
            (->PersisentVector (dec cnt)
                               shift
                               EMPTY-NODE
                               new-tail
                               hash-val
                               meta)
            (and (> shift 5)
                 (nil? (aget (.-array new-root) 1)))
            (->PersistentVector (dec cnt)
                                (- shift 5)
                                (aget (.-array new-root) 0)
                                new-tail
                                hash-val
                                meta)

            :else
            (->PersistentVector (dec cnt)
                                shift
                                new-root
                                new-tail
                                hash-val
                                meta))))))

  IAssociative
  (-assoc [this k v]
    (assert (int? k) "Vectors expect ints as keys")
    (if (and (>= idx 0)
             (< idx cnt))
      (if (>= idx (tail-off this))
        (let [new-tail (array-clone tail)]
          (aset new-tail (bit-and idx 0x01f) val)
          (->PersistentVector cnt shift root new-tail hash-val meta))
        (->PersistentVector cnt shift (do-assoc shift root idx val) tail hash-val meta))
      (if (= idx cnt)
        (-conj this val)
        (throw [:pixie.stdlib/IndexOutOfRange
                "Can only assoc to the end or the contents of a vector"]))))

  IToTransient
  (-transient [this]
    (->TransientVector cnt shift
                       (editable-root root)
                       (editable-tail tail)
                       meta))

  IReduce
  (-reduce [this f init]
    ((fn outer-loop [i acc]
       (if (< i cnt)
         (let [array (array-for this i)]
           ((fn inner-loop [i j acc]
              (if (< j (count array))
                (let [acc (f acc (aget array j))]
                  (if (reduced? acc)
                    @acc
                    (inner-loop (inc i)
                                (inc j)
                                acc)))
                (outer-loop i acc)))
            i 0 acc))
         acc))
     0 init)))

(defn do-assoc [lvl node idx val]
  (let [new-array (array-clone (.-array node))
        ret (if (= lvl 0)
              (aset new-array (bit-and idx 0x01f) val)
              (let [sub-idx (bit-and (bit-shift-right idx lvl) 0x01f)]
                (aset new-array sub-idx (do-assoc (- lvl 5) (aget (.-array node) idx val)))))]
    (->Node (.-edit node) new-array)))


(defn push-tail [this level parent tail-node]
  (let [subidx (bit-and (bit-shift-right (dec (.-cnt this)) level) 0x01f)
        ret-array (array-clone (.-array parent))
        node-to-insert (if (= level 5)
                         tail-node
                         (let [child (aget (.-array parent) subidx)]
                           (if (= child nil)
                             (new-path (.-edit (.-root this))
                                       (- level 5)
                                       tail-node)
                             (push-tail this
                                        (- level 5)
                                        child
                                        tail-node))))]
    (aset ret-array subidx node-to-insert)
    (->Node (.-edit parent) ret-array)))

(defn pop-tail [this level node]
  (let [sub-idx (bit-and (bit-shift-right (dec (.-cnt this)) level) 0x01F)]
    (cond
      (> level 5)
      (let [new-child (pop-tail this
                                (- level 5)
                                (aget (.-array node) sub-idx))]
        (if (or (nil? new-child)
                (= sub-idx 0))
          nil
          (let [root (.-root this)
                ret (->Node (.-edit root)
                            (.-array node))]
            (aset (.-array ret) sub-idx new-child)
            ret)))
      
      (= sub-idx 0)
      nil

      :else
      (let [root (.-root this)
            ret (->Node (.-edit root)
                        (array-clone (.-array node)))]
        (aset (.-array ret) sub-idx nil)
        ret))))

(defn new-path [edit level node]
  (if (= level 0)
    node
    (let [nnode (new-node edit)]
      (aset (.-array nnode) 0 (new-path edit (- level 5) node))
      nnode)))


(def EMPTY (->PersistentVector 0 5 EMPTY-NODE (array 0) nil nil))

(defn vector-from-array [arr]
  (if (< (count arr) 32)
    (->PersistentVector (count arr) 5 EMPTY-NODE arr nil nil)
    (into [] arr)))


;; Transient Vector

#_(deftype Edited [])
(def edited ::edited)


(deftype TransientVector [cnt shift root tail meta]
  IMessageObject
  (-get-field [this field]
    (get-field this field))

  ITransientCollection
  (-conj! [this val]
    (ensure-editable this)
    (let [i cnt]
      (if (< (- i (tail-off this) 32))
        (do (aset tail (bit-and i 0x01F) val)
            (set-field! this :cnt (inc cnt))
            this)
        (let [tail-node (->Node (.-edit root) tail)]
          (set-field! this :tail (make-array 32))
          (aset tail 0 val)
          (if (> (bit-shift-right cnt 5)
                 (bit-shift-left 1 shift))
            (let [root-array (make-array 32)]
              (aset root-array 0 root)
              (aset root-array 1 (new-path (.-edit root) shift tail-node))
              (set-field! this :shift (+ shift 5))
              (set-field! this :root new-root)
              (set-field! this :cnt (inc cnt))
              this)
            (do (set-field this :root (push-tail-transient shift root tail-node))
                (set-field this :cnt (inc cnt))
                this))))))

  ITransient
  (-persistent! [this]
    (ensure-editable this)
    (let [trimmed (make-array (- cnt (tail-off self)))]
      (array-copy tail 0 trimmed 0 (count trimmed))
      (->PersistentVector cnt shift root trimmed nil meta))))


(defn editable-root [node]
  (->Node edited (array-clone (.-array node))))

(defn ensure-editable [node]
  (assert (not (nil? (.-edit node)))
          "Transient used after call to persist!"))

(defn ensure-node-editable [this node]
  (let [root (.-root this)]
    (if (identical? (.-edit node) (.-edit root))
      node
      (->Node (.-edit root) (.-array node)))))

(defn editable-tail [tail]
  (let [ret (make-array 32)]
    (acopy tail 0 ret 0 (count tail))
    ret))

(in-ns :pixie.stdlib)
;; End Persistent Vector

;; Persistent Hash Map

(in-ns :pixie.stdlib.persistent-hash-map)

(def MASK-32 0xFFFFFFFF)


(defprotocol INode
  (-assoc-inode [this shift hash-val key val added-leaf])
  (-find [self shift hash-val key not-found])
  (-reduce-inode [self f init])
  (-without [self shift hash key]))

(defn mask [hash shift]
  (bit-and (bit-shift-right hash shift) 0x01f))

(defn bitpos [hash shift]
  (bit-and (bit-shift-left 1 (mask hash shift)) MASK-32))

(defn index [this bit]
  (bit-count32 (bit-and (.-bitmap this)
                        (dec bit))))


(deftype BitmapIndexedNode [edit bitmap array]
  IMessageObject
  (-get-field [this field]
    (get-field this field))
  
  INode
  (-assoc-inode [this shift hash-val key val added-leaf]
    (let [bit (bitpos hash-val shift)
          idx (index this bit)]
      (if (not= (bit-and bitmap bit) 0)
        (let [key-or-null (aget array (* 2 idx))
              val-or-node (aget array (inc (* 2 idx)))]
          (if (nil? key-or-null)
            (let [n (-assoc-inode val-or-node
                                  (+ shift 5)
                                  (bit-and hash-val MASK-32)
                                  key
                                  val
                                  added-leaf)]
              (if (identical? n val-or-node)
                this
                (->BitmapIndexedNode nil
                                     bitmap
                                     (clone-and-set array (inc (* 2 idx)) n))))
            (if (= key key-or-null)
              (if (identical? val val-or-node)
                this
                (->BitmapIndexedNode nil
                                     bitmap
                                     (clone-and-set array (inc (* 2 idx)) val)))
              (do (reset! added-leaf true)
                  (->BitmapIndexedNode nil bitmap
                                       (clone-and-set2 array
                                                       (* 2 idx) nil
                                                       (inc (* 2 idx))
                                                       (create-node (+ shift 5)
                                                                    key-or-null
                                                                    val-or-node
                                                                    hash-val
                                                                    key
                                                                    val)))))))
        (let [n (bit-count32 bitmap)]
          (if (>= n 16)
            (let [nodes (make-array 32)
                  jdx (mask hash-val shift)]
              (aset nodes jdx (-assoc-inode BitmapIndexedNode-EMPTY
                                            (+ shift 5)
                                            hash-val
                                            key
                                            val
                                            added-leaf))
              (loop [j 0
                     i 0]
                (when (< i 32)
                  (if (not= (bit-and (bit-shift-right bitmap i) 1) 0)
                    (do (if (nil? (aget array j))
                          (aset nodes i (aget array (inc j)))
                          (aset nodes i (-assoc-inode BitmapIndexedNode-EMPTY
                                                      (+ shift 5)
                                                      (pixie.stdlib/hash (aget array j))
                                                      (aget array j)
                                                      (aget array (inc j))
                                                      added-leaf)))
                        (recur (+ 2 j)
                               (inc i)))
                    (recur j
                           (inc i)))))
              (->ArrayNode nil (inc n) nodes))
            (let [new-array (make-array (* 2 (inc n)))]
              (array-copy array 0 new-array 0 (* 2 idx))
              (aset new-array (* 2 idx) key)
              (reset! added-leaf true)
              (aset new-array (inc (* 2 idx)) val)
              (array-copy array (* 2 idx) new-array (* 2 (inc idx)) (* 2 (- n idx)))
              (->BitmapIndexedNode nil (bit-or bitmap bit) new-array)))))))

  (-find [self shift hash-val key not-found]
    (let [bit (bitpos hash-val shift)]
      (if (= (bit-and bitmap bit) 0)
        not-found
        (let [idx (index self bit)
              key-or-null (aget array (* 2 idx))
              val-or-node (aget array (inc (* 2 idx)))]
          (if (nil? key-or-null)
            (-find val-or-node (+ 5 shift) hash-val key not-found)
            (if (= key key-or-null)
              val-or-node
              not-found))))))
  
  (-reduce-inode [this f init]
    (loop [x 0
           acc init]
      (if (< x (count array))
        (let [key-or-nil (aget array x)
              val-or-node (aget array (inc x))
              acc (if (and (nil? key-or-nil)
                           (not (nil? val-or-node)))
                    (-reduce-inode val-or-node f acc)
                    (f acc (map-entry key-or-nil val-or-node)))]
          (if (reduced? acc)
            acc
            (recur (+ 2 x) acc)))
        acc))))

(def BitmapIndexedNode-EMPTY (->BitmapIndexedNode nil (size-t 0) []))

(defn ann [x]
  (assert x)
  x)

(deftype ArrayNode [edit cnt array]
  INode
  (-assoc-inode [this shift hash-val key val added-leaf]
    (let [idx (mask hash-val shift)
          node (aget array idx)]
      (if (nil? node)
        (->ArrayNode nil
                     (inc cnt)
                     (clone-and-set array
                                    idx
                                    (-assoc-inode BitmapIndexedNode-EMPTY
                                                  (+ shift 5)
                                                  hash-val
                                                  key
                                                  val
                                                  added-leaf)))
        (let [n (-assoc-inode node
                            (+ 5 shift)
                            hash-val
                            key
                            val
                            added-leaf)]
          (if (identical? n node)
            this
            (->ArrayNode nil cnt (clone-and-set array idx n)))))))
  (-find [this shift hash-val key not-found]
    (let [idx (mask hash-val shift)
          node (aget array idx)]
      (if (nil? node)
        not-found
        (-find node
               (+ shift 5)
               hash-val
               key
               not-found))))

  (-reduce-inode [this f init]
    (loop [x 0
           acc init]
      (if (< x (count array))
        (let [node (aget array x)]
          (if (not (nil? node))
            (let [acc (-reduce-inode node f acc)]
              (if (reduced? acc)
                acc
                (recur (inc x) acc)))
            (recur (inc x) acc)))
        acc))))

(deftype PersistentHashMap [cnt root has-nil? nil-val hash-val meta]
  IObject
  (-hash [this]
    (if hash-val
      hash-val
      (do (set-field! this :hash-val
                      (transduce cat
                                 pixie.stdlib.hashing/unordered-hash-reducing-fn
                                 this))
          hash-val)))
  
  (-str [this sb]
    (sb "{")
    (let [not-first (atom false)]
      (reduce
       (fn [_ x]
         (if @not-first
           (sb " ")
           (reset! not-first true))
         (-str (key x) sb)
         (sb " ")
         (-str (val x) sb))
       nil
       this))
    (sb "}"))
  
  IMeta
  (-meta [this]
    meta)

  IWithMeta
  (-with-meta [this new-meta]
    (->PersistentHashMap cnt root has-nil? nil-val hash-val new-meta))

  IEmpty
  (-empty [this]
    (-with-meta pixie.stdlib.persistent-hash-map/EMPTY
                meta))
  
  IAssociative
  (-assoc [this key val]
    (if (nil? key)
      (if (identical? val nil-val)
        this
        (->PersistentHashMap cnt root true val nil meta))
      (let [new-root (if (nil? root)
                       BitmapIndexedNode-EMPTY
                       root)
            added-leaf (atom false)
            new-root (-assoc-inode new-root
                                   0
                                   (bit-and (hash key) MASK-32)
                                   key
                                   val
                                   added-leaf)]
        (if (identical? new-root root)
          this
          (->PersistentHashMap (if @added-leaf
                                 (inc cnt)
                                 cnt)
                               new-root
                               has-nil?
                               nil-val
                               nil
                               meta)))))

  ILookup
  (-val-at [this key not-found]
    (if (nil? key)
      (if has-nil?
        nil-val
        not-found)
      (if (nil? root)
        not-found
        (-find root 0
               (bit-and (hash key) MASK-32)
               key
               not-found))))

  IReduce
  (-reduce [this f init]
    (let [acc (if has-nil?
                (f init nil-val)
                init)]
      (if (reduced? acc)
        @acc
        (if root
          (let [acc (-reduce-inode root f acc)]
            (if (reduced? acc)
              @acc
              acc))
          acc)))))

(def EMPTY (->PersistentHashMap (size-t 0) nil false nil nil nil))

(defn create-node [shift key1 val1 key2hash key2 val2]
  (let [key1hash (bit-and (pixie.stdlib/hash key1) MASK-32)]
    (if (= key1hash key2hash)
      (do
        (println "HASH " key1 val1 key2 val2 key1hash key2hash)
        (->HashCollisionNode nil key1hash [key1 val1 key2 val2]))
      (let [added-leaf (atom false)]
        (-> BitmapIndexedNode-EMPTY
            (-assoc-inode shift key1hash key1 val1 added-leaf)
            (-assoc-inode shift key2hash key2 val2 added-leaf))))))

(defn clone-and-set [array i a]
  (let [clone (array-clone array)]
    (aset clone i a)
    clone))

(defn clone-and-set2 [array i a j b]
  (let [clone (array-clone array)]
    (aset clone i a)
    (aset clone j b)
    clone))

(in-ns :pixie.stdlib)

(defn hashmap [& args]
  (loop [idx 0
         acc pixie.stdlib.persistent-hash-map/EMPTY]
    (if (< idx (count args))
      (do (assert (> (- (count args) idx) 1) "hashmap requires even number of args")
          (recur (+ 2 idx)
                 (assoc acc (nth args idx) (nth args (inc idx)))))
      acc)))

;; End Persistent Hash Map
;; Extend Core Types

(extend -invoke Code -invoke)
(extend -invoke NativeFn -invoke)
(extend -invoke VariadicCode -invoke)
(extend -invoke MultiArityFn -invoke)
(extend -invoke Closure -invoke)
(extend -invoke Var -invoke)
(extend -invoke PolymorphicFn -invoke)
(extend -invoke DoublePolymorphicFn -invoke)

(extend -name Keyword -internal-get-name)
(extend -namespace Keyword -internal-get-ns)
(extend -hash Keyword (fn [x]
                        (let [v (-internal-get-hash x)]
                          (if (zero? v)
                            (let [h (pixie.stdlib.hashing/hash-unencoded-chars (str x))]
                              (-internal-store-hash x h)
                              h)
                            v))))

(extend -invoke Keyword (fn
                          ([this o]
                           (-val-at o this nil))
                          ([this o not-found]
                            (-val-at o this not-found))))



(extend -name Symbol -internal-get-name)
(extend -namespace Symbol -internal-get-ns)
(extend -hash Symbol (fn [x]
                        (let [v (-internal-get-hash x)]
                          (if (zero? v)
                            (let [h (pixie.stdlib.hashing/hash-unencoded-chars (str x))]
                              (-internal-store-hash x h)
                              h)
                            v))))

(extend -name String identity)
(extend -namespace String (fn [x] nil))





;(extend -reduce Cons seq-reduce)
;(extend -reduce PersistentList seq-reduce)
;(extend -reduce LazySeq seq-reduce)



;; Buffer

(extend -reduce Buffer
        (fn [b f init]
          (loop [idx 0
                 acc init]
            (if (reduced? acc)
              @acc
              (if (< idx (count b))
                (let [val (pixie.ffi/unpack b idx CUInt8)]
                  (recur (inc idx)
                         (f acc val)))
                acc)))))

;;


(extend -str Bool
  (fn [x sb]
    (if x
      (sb "true")
      (sb "false"))))
(extend -repr Bool -str)

(extend-type Nil
  IObject
  (-str [this f]
    (f "nil"))
  (-repr [this f]
    (f "nil"))
  (-hash [this]
    1000000)
  (-eq [this other]
    (identical? this other))
  
  IDeref
  (-deref [this]
    nil)

  IReduce
  (-reduce [this f init]
    init))


(extend -with-meta Nil (fn [self _] nil))
(extend -contains-key Nil (fn [_ _] false))

(extend -hash Integer pixie.stdlib.hashing/hash-int)

(extend -eq Integer -num-eq)
(extend -eq Float -num-eq)
(extend -eq Ratio -num-eq)

(defn vector [& args]
  (pixie.stdlib.persistent-vector/vector-from-array args))


;; End Extend Core Types

;; NS functions

(defn refer
  {:doc "Refer to the specified vars from a namespace directly.

Supported filters:
  :rename   refer to the given vars under a different name
  :exclude  don't refer the given vars
  :refer
    :all    refer all vars
    :refer  refer only the given vars
    :only   same as refer

user => (refer 'pixie.string :refer :all)
user => (refer 'pixie.string :only '(index-of starts-with? ends-with?))
user => (refer 'pixie.string :rename '{index-of find})
user => (refer 'pixie.string :exclude '(substring))"
   :added "0.1"}
  [from-ns ns-sym & filters]
  (println ns-sym)
  (let [ns (or (the-ns ns-sym) (throw [:pixie.stdlib/NamespaceNotFoundException
                                       (str "No such namespace: " ns-sym)]))
        filters (apply hashmap filters)
        rename (or (:rename filters) {})
        exclude (:exclude filters)
        rname (or (:as filters)
                  ns-sym)]
    (println "refering " from-ns ns-sym)
    (-add-refer from-ns ns-sym rname)
    (if (= :all (:refer filters))
      (-refer-all from-ns rname)
      (doseq [sym (:refer filters)]
        (-add-refer from-ns rname sym sym)))

    (doseq [[from to] (:rename filters)]
      (-add-refer from-ns rname from to))

    (doseq [nm (:exclude filters)]
      (-add-exclude from-ns rname nm))
    
    nil))


;; End NS Functions

;; Delay

(deftype Delay [f val]
  (-deref [this]
    (when f
      (set-field! :val (f))
      (set-field! :f nil))
    val))

(defn -delay [f]
  (->Delay f nil))

;; End Delay 

;; Dynamic Vars

(defeffect EDynamicVar
  (-dynamic-var-lookup [this])
  (-dynamic-var-set [this val]))

(deftype DynamicVar [x]
  IEffect
  (-effect-val [this y]
    (println "Effect Val" y)
    (fn val-fn [s] y))
  
  (-effect-return [this f]
    (println "Effect Return " f)
    (f x))

  EDynamicVar
  (-dynamic-var-lookup [this k]
    (println "lookup")
    (fn lookup-fn [s]
      (println "lookup -> " s k)
      ((k s) s)))

  (-dynamic-var-set [this s' k]
    (println "call set " s' k)
    (fn [s]
      (println "Setting to |  " s' s)
      ((k nil) s')))


  IDeref
  (-deref [this]
    (-dynamic-var-lookup this))

  IReset
  (-reset! [this v]
    (-dynamic-var-set this v)))

(defn dynamic-var
  ([]
   (dynamic-var nil))
  ([v]
   (->DynamicVar v)))


;;

;; Multimethod stuff
#_(comment


(deftype MultiMethod [name dispatch-fn default-val methods]
  IFn
  (-invoke [self & args]
    (let [dispatch-val (apply dispatch-fn args)
          method (if (contains? @methods dispatch-val)
                   (get @methods dispatch-val)
                   (get @methods default-val))
          _ (assert method (str "no method defined for " dispatch-val " on " name))]
      (try
        (apply method args)
        (catch ex
            (throw (add-exception-info ex (str "In multimethod "
                                               name
                                               " dispatching on "
                                               dispatch-val
                                               "\n") args)))))))

(defmacro defmulti
  {:doc "Define a multimethod, which dispatches to its methods based on dispatch-fn."
   :examples [["(defmulti greet first)"]
              ["(defmethod greet :hi [[_ name]] (str \"Hi, \" name \"!\"))"]
              ["(defmethod greet :hello [[_ name]] (str \"Hello, \" name \".\"))"]
              ["(greet [:hi \"Jane\"])" nil "Hi, Jane!"]]
   :signatures [[name dispatch-fn & options]]
   :added "0.1"}
  [name & args]
  (let [[meta args] (if (string? (first args))
                      [{:doc (first args)} (next args)]
                      [{} args])
        [meta args] (if (map? (first args))
                      [(merge meta (first args)) (next args)]
                      [meta args])
        dispatch-fn (first args)
        options (apply hashmap (next args))]
    `(def ~name (->MultiMethod ~(str name) ~dispatch-fn ~(get options :default :default) (atom {})))))

(defmacro defmethod
  {:doc "Define a method of a multimethod. See `(doc defmulti)` for details."
   :signatures [[name dispatch-val [param*] & body]]
   :added "0.1"}
  [name dispatch-val params & body]
  `(do
     (let [methods (.methods ~name)]
       (swap! methods
              assoc
              ~dispatch-val (fn ~params
                              ~@body))
       ~name)))
)

;; End Multimethods

;; LibC Stuff
(def load-paths (atom ["." ""]))

(defn ffi-library [nm]
  (reduce
   (fn [_ x]
     (when-let [l (-ffi-library (str x (name nm)))]
       (reduced l)))
   nil
   @load-paths))


(def libc (ffi-library pixie.platform/lib-c-name))


;;



;; Mutimethods

(deftype MultiMethod [dispatch-fn default-val methods]
  IFn
  (-invoke [self & args]
    (let [dispatch-val (apply dispatch-fn args)
          method (if (contains? @methods dispatch-val)
                   (get @methods dispatch-val)
                   (get @methods default-val))
          _ (assert method (str "no method defined for " dispatch-val))]
      (apply method args))))



;;

type int
type float
type string

type unit = {}

datatype bool = False | True


(** Basic type classes *)

class eq
val eq : t ::: Type -> eq t -> t -> t -> bool
val ne : t ::: Type -> eq t -> t -> t -> bool
val eq_int : eq int
val eq_string : eq string
val eq_bool : eq bool


(** SQL *)

con sql_table :: {Type} -> Type

(*** Queries *)

con sql_query :: {{Type}} -> {Type} -> Type
con sql_query1 :: {{Type}} -> {{Type}} -> {Type} -> Type
con sql_exp :: {{Type}} -> {{Type}} -> {Type} -> Type -> Type

con sql_subset :: {{Type}} -> {{Type}} -> Type
val sql_subset : keep_drop :: {({Type} * {Type})}
        -> sql_subset
                (fold (fn nm => fn fields :: ({Type} * {Type}) => fn acc =>
                        [nm] ~ acc => fields.1 ~ fields.2 =>
                        [nm = fields.1 ++ fields.2] ++ acc) [] keep_drop)
                (fold (fn nm => fn fields :: ({Type} * {Type}) => fn acc =>
                        [nm] ~ acc =>
                        [nm = fields.1] ++ acc) [] keep_drop)
val sql_subset_all : tables :: {{Type}}
        -> sql_subset tables tables

val sql_query1 : tables ::: {{Type}}
        -> grouped ::: {{Type}}
        -> selectedFields ::: {{Type}}
        -> selectedExps ::: {Type}
        -> {From : $(fold (fn nm => fn fields :: {Type} => fn acc =>
                [nm] ~ acc => [nm = sql_table fields] ++ acc) [] tables),
            Where : sql_exp tables [] [] bool,
            GroupBy : sql_subset tables grouped,
            Having : sql_exp grouped tables [] bool,
            SelectFields : sql_subset grouped selectedFields,
            SelectExps : $(fold (fn nm => fn t :: Type => fn acc =>
                [nm] ~ acc => [nm = sql_exp grouped tables [] t] ++ acc) [] selectedExps) }
        -> sql_query1 tables selectedFields selectedExps

type sql_relop 
val sql_union : sql_relop
val sql_intersect : sql_relop
val sql_except : sql_relop
val sql_relop : tables1 ::: {{Type}}
        -> tables2 ::: {{Type}}
        -> selectedFields ::: {{Type}}
        -> selectedExps ::: {Type}
        -> sql_relop
        -> sql_query1 tables1 selectedFields selectedExps
        -> sql_query1 tables2 selectedFields selectedExps
        -> sql_query1 selectedFields selectedFields selectedExps

type sql_direction
val sql_asc : sql_direction
val sql_desc : sql_direction

con sql_order_by :: {{Type}} -> {Type} -> Type
val sql_order_by_Nil : tables ::: {{Type}} -> exps :: {Type} -> sql_order_by tables exps
val sql_order_by_Cons : tables ::: {{Type}} -> exps ::: {Type} -> t ::: Type
        -> sql_exp tables [] exps t -> sql_order_by tables exps
        -> sql_order_by tables exps

type sql_limit
val sql_no_limit : sql_limit
val sql_limit : int -> sql_limit

type sql_offset
val sql_no_offset : sql_offset
val sql_offset : int -> sql_offset

val sql_query : tables ::: {{Type}}
        -> selectedFields ::: {{Type}}
        -> selectedExps ::: {Type}
        -> {Rows : sql_query1 tables selectedFields selectedExps,
            OrderBy : sql_order_by tables selectedExps,
            Limit : sql_limit,
            Offset : sql_offset}
        -> sql_query selectedFields selectedExps

val sql_field : otherTabs ::: {{Type}} -> otherFields ::: {Type} -> fieldType ::: Type -> agg ::: {{Type}}
        -> exps ::: {Type}
        -> tab :: Name -> field :: Name
        -> sql_exp ([tab = [field = fieldType] ++ otherFields] ++ otherTabs) agg exps fieldType

val sql_exp : tabs ::: {{Type}} -> agg ::: {{Type}} -> t ::: Type -> rest ::: {Type} -> nm :: Name
        -> sql_exp tabs agg ([nm = t] ++ rest) t

class sql_injectable
val sql_bool : sql_injectable bool
val sql_int : sql_injectable int
val sql_float : sql_injectable float
val sql_string : sql_injectable string
val sql_inject : tables ::: {{Type}} -> agg ::: {{Type}} -> exps ::: {Type} -> t ::: Type
        -> sql_injectable t -> t -> sql_exp tables agg exps t

con sql_unary :: Type -> Type -> Type
val sql_not : sql_unary bool bool
val sql_unary : tables ::: {{Type}} -> agg ::: {{Type}} -> exps ::: {Type} -> arg ::: Type -> res ::: Type
        -> sql_unary arg res -> sql_exp tables agg exps arg -> sql_exp tables agg exps res

con sql_binary :: Type -> Type -> Type -> Type
val sql_and : sql_binary bool bool bool
val sql_or : sql_binary bool bool bool
val sql_binary : tables ::: {{Type}} -> agg ::: {{Type}} -> exps ::: {Type}
        -> arg1 ::: Type -> arg2 ::: Type -> res ::: Type
        -> sql_binary arg1 arg2 res -> sql_exp tables agg exps arg1 -> sql_exp tables agg exps arg2
        -> sql_exp tables agg exps res

type sql_comparison
val sql_eq : sql_comparison
val sql_ne : sql_comparison
val sql_lt : sql_comparison
val sql_le : sql_comparison
val sql_gt : sql_comparison
val sql_ge : sql_comparison
val sql_comparison : tables ::: {{Type}} -> agg ::: {{Type}} -> exps ::: {Type}
        -> t ::: Type
        -> sql_comparison
        -> sql_exp tables agg exps t -> sql_exp tables agg exps t
        -> sql_exp tables agg exps bool

val sql_count : tables ::: {{Type}} -> agg ::: {{Type}} -> exps ::: {Type}
        -> unit -> sql_exp tables agg exps int

con sql_aggregate :: Type -> Type
val sql_aggregate : tables ::: {{Type}} -> agg ::: {{Type}} -> exps ::: {Type} -> t ::: Type
        -> sql_aggregate t -> sql_exp agg agg exps t -> sql_exp tables agg exps t

class sql_summable
val sql_summable_int : sql_summable int
val sql_summable_float : sql_summable float
val sql_avg : t ::: Type -> sql_summable t -> sql_aggregate t
val sql_sum : t ::: Type -> sql_summable t -> sql_aggregate t

class sql_maxable
val sql_maxable_int : sql_maxable int
val sql_maxable_float : sql_maxable float
val sql_maxable_string : sql_maxable string
val sql_max : t ::: Type -> sql_maxable t -> sql_aggregate t
val sql_min : t ::: Type -> sql_maxable t -> sql_aggregate t


(*** Executing queries *)

con transaction :: Type -> Type
val return : t ::: Type
        -> t -> transaction t
val bind : t1 ::: Type -> t2 ::: Type
        -> transaction t1 -> (t1 -> transaction t2)
        -> transaction t2

val query : tables ::: {{Type}} -> exps ::: {Type} -> tables ~ exps
        -> state ::: Type
        -> sql_query tables exps
        -> ($(exps ++ fold (fn nm (fields :: {Type}) acc => [nm] ~ acc => [nm = $fields] ++ acc) [] tables)
                -> state
                -> transaction state)
        -> state
        -> transaction state


(** XML *)

con tag :: {Type} -> {Unit} -> {Unit} -> {Type} -> {Type} -> Type


con xml :: {Unit} -> {Type} -> {Type} -> Type
val cdata : ctx ::: {Unit} -> use ::: {Type} -> string -> xml ctx use []
val tag : attrsGiven ::: {Type} -> attrsAbsent ::: {Type} -> attrsGiven ~ attrsAbsent
        -> ctxOuter ::: {Unit} -> ctxInner ::: {Unit}
        -> useOuter ::: {Type} -> useInner ::: {Type} -> useOuter ~ useInner
        -> bindOuter ::: {Type} -> bindInner ::: {Type} -> bindOuter ~ bindInner
        -> $attrsGiven
        -> tag (attrsGiven ++ attrsAbsent) ctxOuter ctxInner useOuter bindOuter
        -> xml ctxInner useInner bindInner
        -> xml ctxOuter (useOuter ++ useInner) (bindOuter ++ bindInner)
val join : ctx ::: {Unit} 
        -> use1 ::: {Type} -> bind1 ::: {Type} -> bind2 ::: {Type}
        -> use1 ~ bind1 -> bind1 ~ bind2
        -> xml ctx use1 bind1
        -> xml ctx (use1 ++ bind1) bind2
        -> xml ctx use1 (bind1 ++ bind2)
val useMore : ctx ::: {Unit} -> use1 ::: {Type} -> use2 ::: {Type} -> bind ::: {Type}
        -> use1 ~ use2
        -> xml ctx use1 bind
        -> xml ctx (use1 ++ use2) bind

con xhtml = xml [Html]
con page = xhtml [] []

(*** HTML details *)

con html = [Html]
con head = [Head]
con body = [Body]
con lform = [Body, LForm]

val head : unit -> tag [] html head [] []
val title : unit -> tag [] head [] [] []

val body : unit -> tag [] html body [] []
con bodyTag = fn attrs :: {Type} => ctx ::: {Unit} -> [Body] ~ ctx -> unit
        -> tag attrs ([Body] ++ ctx) ([Body] ++ ctx) [] []
con bodyTagStandalone = fn attrs :: {Type} => ctx ::: {Unit} -> [Body] ~ ctx -> unit
        -> tag attrs ([Body] ++ ctx) [] [] []

val br : bodyTagStandalone []

val p : bodyTag []
val b : bodyTag []
val i : bodyTag []
val font : bodyTag [Size = int, Face = string]

val h1 : bodyTag []
val li : bodyTag []

val a : bodyTag [Link = page]

val lform : ctx ::: {Unit} -> [Body] ~ ctx -> bind ::: {Type}
        -> xml lform [] bind
        -> xml ([Body] ++ ctx) [] []
con lformTag = fn ty :: Type => fn inner :: {Unit} => fn attrs :: {Type} =>
        ctx ::: {Unit} -> [LForm] ~ ctx
        -> nm :: Name -> unit
        -> tag attrs ([LForm] ++ ctx) inner [] [nm = ty]
val textbox : lformTag string [] []
val password : lformTag string [] []
val ltextarea : lformTag string [] []

val checkbox : lformTag bool [] []

con radio = [Body, Radio]
val radio : lformTag string radio []
val radioOption : unit -> tag [Value = string] radio [] [] []

con select = [Select]
val lselect : lformTag string select []
val loption : unit -> tag [Value = string] select [] [] []

val submit : ctx ::: {Unit} -> [LForm] ~ ctx
        -> use ::: {Type} -> unit
        -> tag [Action = $use -> page] ([LForm] ++ ctx) ([LForm] ++ ctx) use []

//All the fields have to be set for reactivity
export var UserView = () => ({
   id : 0,
   username : "???",
   avatar : "0"
});

export var MessageView = () => ({
   id : 0,
   text : "",
   createUser : UserView(),
   createDate : "",
   editDate : "",
   edited : false,
   values : { }
});


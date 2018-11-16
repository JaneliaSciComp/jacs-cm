db = db.getSiblingDB('jade')
db.createUser(
  {
    user: "jadeUser",
    pwd: "ja1234de",
    roles: [ { role: "readWrite", db: "jade" } ],
    passwordDigestor : "server"
  }
);

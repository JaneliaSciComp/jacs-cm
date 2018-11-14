db = db.getSiblingDB('jacs')
db.createUser(
  {
    user: "jacsUser",
    pwd: "ja1234cs",
    roles: [ { role: "readWrite", db: "jacs" } ],
    passwordDigestor : "server"
  }
);

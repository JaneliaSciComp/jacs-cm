rsconf = {
  _id : "rsJacs",
  members: [
    { _id : 0, host : "mongo1:27017" },
    { _id : 1, host : "mongo2:27017" },
    { _id : 2, host : "mongo3:27017", arbiterOnly: true}
  ]
}

rs.initiate(rsconf);

rs.status();

rs.conf();

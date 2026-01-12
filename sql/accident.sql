404 user_id 1 |  | a shift_range | delta 1.300 | end_date 1523664775 | start_date 1491005555 |

/*
affected:339
after:{_first: "2017-08-29 03:33:45 = 0.52299999999999991", _last: "2017-10-10 21:05:13 = 5.0750000000000002", max: 5.322, min: 0.391}
before:{_first: "2017-08-29 03:33:45 = 1.823", _last: "2017-10-10 21:05:13 = 6.375", max: 6.622, min: 1.691}
*/

user_id 46 |  | a shift_range | delta 1000 | end_date 1523583769 | start_date 1523559981 |
user_id 46 |  | a shift_range | delta 1.000 | end_date 1523583769 | start_date 1523559981 |
user_id 46 |  | a shift_range | delta 1.000 | end_date 1523583769 | start_date 1523559981 |
user_id 46 |  | a shift_range | delta 1.300 | end_date 1523583769 | start_date 1523559981 |

/*
H.Post({a:'shift_range',delta:-(1000+1+1+1.3),start_date:1523559981,end_date:1523583769,revert:true},console.log);

affected:291
after:{_first: "2018-04-12 19:06:30 = 3.9069999999999254", _last: "2018-04-13 00:13:21 = 2603.3029999999999", max: 2604.2969999999996, min: 3.8489999999999327}
before:{_first: "2018-04-12 19:06:30 = 1007.2069999999999", _last: "2018-04-13 00:13:21 = 3606.6030000000001", max: 3607.5969999999998, min: 1007.1489999999999}
*/

user_id 46 |  | a shift_range | delta 1300 | end_date 1523583769 | start_date 1523560861 |
user_id 46 |  | a shift_range | delta 1300 | end_date 1523583769 | start_date 1523560861 |

/*
H.Post({a:'shift_range',delta:-(1.3+1.3),start_date:1523560861,end_date:1523583769,revert:true},console.log);

affected:277
after:{_first: "2018-04-12 19:21:14 = 2601.297", _last: "2018-04-13 00:13:21 = 2600.703", max: 2601.6969999999997, min: 2600.703}
before:{_first: "2018-04-12 19:21:14 = 2603.8969999999999", _last: "2018-04-13 00:13:21 = 2603.3029999999999", max: 2604.2969999999996, min: 2603.303}
*/

/*
H.Post({a:'shift_range',delta:-(1300+1300+1000+1+1+1.3),start_date:1523560861,end_date:1523583769,revert:true},console.log);

affected:277
after:{_first: "2018-04-12 19:21:14 = -1001.8029999999999", _last: "2018-04-13 00:13:21 = -1002.3969999999999", max: -1001.4030000000002, min: -1002.3969999999999}
before:{_first: "2018-04-12 19:21:14 = 2601.4970000000003", _last: "2018-04-13 00:13:21 = 2600.9030000000002", max: 2601.897, min: 2600.9030000000002}

H.Post({a:'shift_range',delta:(1300+1300+1000+1+1+1.3),start_date:1523560861,end_date:1523583769,revert:true},console.log);

affected:277
after:{_first: "2018-04-12 19:21:14 = 3607.1970000000001", _last: "2018-04-13 00:13:21 = 3606.6030000000001", max: 3607.5969999999998, min: 3606.603}
before:{_first: "2018-04-12 19:21:14 = 3.8970000000001619", _last: "2018-04-13 00:13:21 = 3.303000000000111", max: 4.296999999999798, min: 3.303000000000111}
*/

user_id 46 |  | a shift_range | delta 1.3 | end_date 1523583769 | start_date 1523559657 |

/*
H.Post({a:'shift_range',delta:-1.3,start_date:1523559657,end_date:1523583769,revert:true},console.log);

affected:291
after:{_first: "2018-04-12 19:06:30 = 0.20699999999988061", _last: "2018-04-13 00:13:21 = -1003.6969999999999", max: 0.25000000000000067, min: -1003.6969999999999}
before:{_first: "2018-04-12 19:06:30 = 1.5069999999998807", _last: "2018-04-13 00:13:21 = -1002.3969999999999", max: 1.5500000000000007, min: -1002.3969999999999}
*/

user_id 1 |  | a shift_range | delta 1.2 | end_date 1523583769 | start_date 1523559600 |

/*
H.Post({a:'shift_range',delta:-1.2,start_date:1523559600,end_date:1523583769,revert:true},console.log);

affected:291
after:{_first: "2018-04-12 19:06:30 = -0.99300000000011934", _last: "2018-04-13 00:13:21 = -1004.8969999999999", max: -0.9499999999999993, min: -1004.8969999999999}
before:{_first: "2018-04-12 19:06:30 = 0.20699999999988061", _last: "2018-04-13 00:13:21 = -1003.6969999999999", max: 0.25000000000000067, min: -1003.6969999999999}
*/

user_id 1 |  | a shift_range | delta -1000 | end_date 1523583720 | start_date 1523559600 |
user_id 1 |  | a shift_range | delta -1000 | end_date 1523583720 | start_date 1523559600 |
user_id 1 |  | a shift_range | delta -1000 | end_date 1523583720 | start_date 1523559600 |
user_id 1 |  | a shift_range | delta 1000 | end_date 1523583720 | start_date 1523559600 |
user_id 1 |  | a shift_range | delta 1000 | end_date 1523583720 | start_date 1523559600 |
user_id 1 |  | a shift_range | delta -8.2 | end_date 1523583720 | start_date 1523559600 |

/*
H.Post({a:'shift_range',delta:1008.2,start_date:1523559600,end_date:1523583720,revert:true},console.log);

affected:291
after:{_first: "2018-04-12 19:06:30 = 1007.2069999999999", _last: "2018-04-13 00:13:21 = 3.303000000000111", max: 1007.25, min: 3.303000000000111}
before:{_first: "2018-04-12 19:06:30 = -0.99300000000011934", _last: "2018-04-13 00:13:21 = -1004.8969999999999", max: -0.9499999999999993, min: -1004.8969999999999}
*/
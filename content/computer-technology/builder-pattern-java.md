---
title: The Builder Pattern in Java
---

## Summary

If you find yourself writing several variations of a constructor or function to make them easier to invoke, or if you find yourself instantiating a class and then calling 5 or more "setXXX()" functions to configure it... the builder pattern might be for you.  The builder pattern lets you create objects with syntax like:

```
DataTable table = new TableReader.Builder()
    .file("myfile.txt")
    .sep("|")
    .header(false)
    .columnNames("store_id", "division_number", "store_number").build().readTable();
```

This is an alternative to putting all those parameters into a single function/constructor of invoking a bunch of setters one-at-a-time.  The builder pattern is used in Apache Avro and other places where convenience on the user's end amid complicated (and frequently optional) parameters is important.  It also allows you to create your data classes as Immutable objects with all properties set in the constructor.  There seems to be a preference amid developers lately for this type of immutability in some of their objects.

## Motivation

Have you ever been jealous of Python or R programmers who get to write code like this:

```
data <- read.table(file="myfile.txt", sep="|", header=FALSE, col.names=c("store_id","division_number", "store_number"))
```

The definition of this R function defines 25 parameters:

```
read.table(file, header = FALSE, sep = "", quote = "\"'",
           dec = ".", numerals = c("allow.loss", "warn.loss", "no.loss"),
           row.names, col.names, as.is = !stringsAsFactors,
           na.strings = "NA", colClasses = NA, nrows = -1,
           skip = 0, check.names = TRUE, fill = !blank.lines.skip,
           strip.white = FALSE, blank.lines.skip = TRUE,
           comment.char = "#",
           allowEscapes = FALSE, flush = FALSE,
           stringsAsFactors = default.stringsAsFactors(),
           fileEncoding = "", encoding = "unknown", text, skipNul = FALSE)
```

Typically, only 3 or 4 of these are used at any given time.  But sometimes you will need to use one of the less common options.

As a Java programmer, it's easy to get a bit envious of the resulting simplicity (at least on the invoking side) for these types of languages.  We would never want to define a Java function with 25 parameters.  Keeping track of which one was which (without having the "name = " convention) would be insanity.  This is where the builder pattern really shines.  The builder pattern would allow us to use something like the following to perform this same task:

```
DataTable table = new TableReader.Builder()
    .file("myfile.txt")
    .sep("|")
    .header(false)
    .columnNames("store_id", "division_number", "store_number").build().readTable();
```

Sure it's still a little verbose... but it's better than:

```
TableReader reader = new TableReader();
reader.setFile("myfile.txt");
reader.setSep("|");
reader.setHeader(false);
reader.setColumnNames("store_id", "division_number", "store_number");
DataTable table = reader.readTable();
```

and it's way better than:

```
DataTable table = new TableReader(
    "myfile.txt", "|", null, null, false,
     new String [] {"store_id", "division_number", "store_number"}).readTable();
```

NOTE: The 'nulls' indicate that we'd likely have to define 10 or so variations of this files with different parameter signatures, and we still might not have one that fits our needs exactly. So we'd find the closest one and omit unneeded parameters.

## Implementation

This article provides a great overview of how to use the builder pattern in Java.  The code patterns they use are shown below:

```
public class User {

  private final String firstName; // required
  private final String lastName;  // required
  private final int age;          // optional
  private final String phone;     // optional
  private final String address;   // optional

  private User(Builder builder) {
    this.firstName = builder.firstName;
    this.lastName  = builder.lastName;
    this.age       = builder.age;
    this.phone     = builder.phone;
    this.address   = builder.address;
  }

  public String getFirstName() {
    return firstName;
  }

  public String getLastName() {
    return lastName;
  }

  public int getAge() {
    return age;
  }

  public String getPhone() {
    return phone;
  }

  public String getAddress() {
    return address;
  }

  public static class Builder {

    private final String firstName;
    private final String lastName;
    private int age;
    private String phone;
    private String address;

    public Builder(String firstName, String lastName) {
      this.firstName = firstName;
      this.lastName = lastName;
    }

    public Builder age(int age) {
      this.age = age;
      return this;
    }

    public Builder phone(String phone) {
      this.phone = phone;
      return this;
    }

    public Builder address(String address) {
      this.address = address;
      return this;
    }

    public User build() {
      return new User(this);
    }

  }
}
```

The object can then be created with:

```
public User getUser() {
  return new
    User.Builder("Jhon", "Doe")
    .age(30)
    .phone("1234567")
    .address("Fake address 1234")
    .build();
}
```

Note that in the example above they've gone as far as to create a private constructor so that the builder is the only way to create this option.  That might be a step too far... especially if you have something that you want to work as a configurable bean that Spring or Guice might create for you.

[Apache Avro](https://avro.apache.org/docs/1.8.1/gettingstartedjava.html) uses a similar syntax, except that instead of using "new User.Builder()" they would use "User.newBuilder()".  It's just a matter of preference at that point.

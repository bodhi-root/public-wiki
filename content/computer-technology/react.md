---
title: React Notes
---

Notes and code snippets for things I keep forgetting...

## Iterating over Lists

([Link to React documentation](https://reactjs.org/docs/lists-and-keys.html))

React's insistence of using normal JavaScript over fancy "magic" is one of the reasons I love it, but it seems I don't know enough about regular JavaScript to remember how to iterate over lists.

### Inline Map

```
render() {
  return(
    <ul>
      {
        objectArray.map((object, index) =>
          <li key={index}>{object.name}</li>
        )
      }
    </ul>
  );
}
```

"map" is a function that iterates over the elements of an array and returns one object for each element.  In this case, we return a JSX object, and the array of JSX objects gets rendered by react.  Note that we use a "key" attribute to uniquely identify items in the list.  This improves React performance, and if you don't do it you'll get a warning in the console.  Using the index of the object in the array is a simple way to get a unique key.

The "=>" operator is an arrow function.  It is a condensed way of writing:

```
objectArray.map(function(object, index) {
  return(
    <li key={index}>{object.name}</li>
  );
})
```

Sometimes the full format is useful if you want to declare some variables inside the mapping function.  However, if your code gets too big, you're likely better off moving the logic into another function and calling it:

```
objectArray.map((object, index) => this.renderItem(object, index))
```

### Iterating over Object Properties

```
var obj = {a: 1, b: 2, c: 3};

for (const prop in obj) {
  console.log(`obj.${prop} = ${obj[prop]}`);
}
```

## Conditional Rendering

([Link to React documentation](https://reactjs.org/docs/conditional-rendering.html))

There are a few paradigms here.  The ones below are the most common for me.

### Inline if using a logical "&&" operator

```
render() {
  return(
    <div>
      {someBoolean &&
        <ElementToRender />
      }
    </div>
  );
}
```

### Element variables

```
render() {
  let component = null;
  if (someBoolean) {
    component = <ElementToRender />
  }

  return(
    <div>
      {component}
    </div>
  );
}
```

## React Router

React's router is an interesting thing.  It took me quite a while to figure out a way to use it that worked correctly when components refresh without re-mounting.  To begin with, you define your high-level routes in your highest-level component (typically something called "App"):

```
<Router>
  <div>
    <PageHeader />
    <div className="body">
      <Route exact path="/" component={HomePage} />
      <Route path="/types" component={TypeListPage} />
      <Route path="/list/:typeId" component={ObjectListPage} />
      <Route path="/object/:objectId" component={ObjectDetailPage} />
      <Route path="/search" component={SearchPage} />
    </div>
  </div>
</Router>
```

This app will inspect the URL of pages to see if they match the "path" templates and forward to the respective components.  Whatever content the components return will be rendered inside of the enclosing ```<div>```.  This means that the code above will always show the same PageHeader at the top of the page.  Only the body will change in response to routes.

The components we invoke then tend to look like this:

```
export class ObjectDetailPage extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      object: {},
      objectReady: false
    };
  }

  componentDidMount() {
    this.loadObject();
  }
  componentDidUpdate(prevProps, prevState) {
    if (this.props.match.params.objectId !==
        prevProps.match.params.objectId) {
      this.setState({object: undefined, objectReady: false});   //clear previous data
      this.loadObject();
    }
  }

  loadObject() {
    const objectId = this.props.match.params.objectId;  //route params passed in from router
    const parent = this;

    objectService.getObject(objectId)
      .then(response => {
        parent.setState({object: response.data, objectReady: true});
      })
      .catch(error => console.log(error));
  }

  render() {
    if (this.state.objectReady === false) {
      return(<span>Loading...</span>);
    }

    return(
      <div>
        <h2>{this.state.object.name}</h2>
        ...
      </div>
    );
  }
}
```

This page will asynchronously load an object (using an axios web service).  It reads the ID of the object from the route parameters and then displays it.  This should be relatively simple, but the piece that took me forever was the "componentDidUpdate()" part.  Without this, it will render correctly the first time.  If someone clicks a link that takes them to the same page route but with a different route parameter, the component will note re-mount.  Instead, new properties are set and the component re-renders.  "componentDidUpdate()" is the best way to tap into these events.  The React documentation warns that you shouldn't use this function often, but this is actually one of the cases where they do suggest it is used.  Their documentation recommends checking for any changes in the properties that would invoke a new asynchronous object load, and if detected, adjust the state and invoke the asynchronous load just as shown.  It's easy once you see it, but this took a few weeks to figure out...

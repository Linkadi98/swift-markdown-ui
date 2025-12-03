import SwiftUI

@available(iOS 15.0, *)
struct ContentView: View {
    var body: some View {
        NavigationView {
            Form {
                Section("Formatting") {
                    NavigationLink {
                        HeadingsView()
                            .navigationTitle("Headings")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                            Label("Headings", systemImage: "textformat.size")
                        } else {
                            Text("Headings")
                        }
                    }
                    NavigationLink {
                        ListsView()
                            .navigationTitle("Lists")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                            Label("Lists", systemImage: "list.bullet")
                        } else {
                            Text("Lists")
                        }
                    }
                    NavigationLink {
                        TextStylesView()
                            .navigationTitle("Text Styles")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                            Label("Text Styles", systemImage: "textformat.abc")
                        } else {
                            Text("Text Styles")
                        }
                    }
                    NavigationLink {
                        QuotesView()
                            .navigationTitle("Quotes")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                            Label("Quotes", systemImage: "text.quote")
                        } else {
                            Text("Quotes")
                        }
                    }
                    NavigationLink {
                        CodeView()
                            .navigationTitle("Code")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                            Label("Code", systemImage: "curlybraces")
                        } else {
                            Text("Code")
                        }
                    }
                    NavigationLink {
                        ImagesView()
                            .navigationTitle("Images")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                            Label("Images", systemImage: "photo")
                        } else {
                            Text("Images")
                        }
                    }
                    NavigationLink {
                        TablesView()
                            .navigationTitle("Tables")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                            Label("Tables", systemImage: "tablecells")
                        } else {
                            Text("Tables")
                        }
                    }
                }
                Section("Extensibility") {
                    NavigationLink {
                        CodeSyntaxHighlightView()
                            .navigationTitle("Syntax Highlighting")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                            Label(
                                "Syntax Highlighting", systemImage: "circle.grid.cross.left.filled")
                        } else {
                            Text("Syntax Highlighting")
                        }
                    }
                    NavigationLink {
                        ImageProvidersView()
                            .navigationTitle("Image Providers")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                            Label("Image Providers", systemImage: "powerplug")
                        } else {
                            Text("Image Providers")
                        }
                    }
                }
                Section("Other") {
                    NavigationLink {
                        FacebookStyleDemoView()
                            .navigationTitle("Facebook Style Posts")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                            Label("Facebook Style Posts", systemImage: "rectangle.3.group")
                        } else {
                            Text("Facebook Style Posts")
                        }
                    }
                    NavigationLink {
                        TextureMarkdownDemoView()
                            .navigationTitle("Texture Markdown")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                            Label("Texture Markdown", systemImage: "doc.text")
                        } else {
                            Text("Texture Markdown")
                        }
                    }
                    NavigationLink {
                        ExpandableMarkdownDemoView()
                            .navigationTitle("Expandable Markdown")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                            Label("Expandable Markdown", systemImage: "doc.text")
                        } else {
                            Text("Expandable Markdown")
                        }
                    }
                    NavigationLink {
                        DingusView()
                            .navigationTitle("Dingus")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                            Label("Dingus", systemImage: "character.cursor.ibeam")
                        } else {
                            Text("Dingus")
                        }
                    }
                    NavigationLink {
                        RepositoryReadmeView()
                            .navigationTitle("Repository README")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                            Label("Repository README", systemImage: "doc.text")
                        } else {
                            Text("Repository README")
                        }
                    }
                    NavigationLink {
                        LazyLoadingView()
                            .navigationTitle("Lazy Loading")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
                            Label("Lazy Loading", systemImage: "scroll")
                        } else {
                            Text("Lazy Loading")
                        }
                    }
                }
            }
            .navigationTitle("MarkdownUI")
        }
    }
}

@available(iOS 15.0, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

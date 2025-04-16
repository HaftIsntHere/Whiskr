import SwiftUI
import CoreML
import Foundation
import UIKit

struct GroceryItem: Identifiable, Codable {
    var id = UUID()
    var name: String
    var purchased: Bool = false
}

struct ingredient: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
}

struct Recipe: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var shortDescription: String
    var ingredients: [String]
    var steps: [String]
    var difficulty: String
    var time: String
    var image: String // base64-encoded image
}

struct ContentView: View {
    let userDefaultsKey = "groceryList"

    @State private var groceries: [GroceryItem] = []
    @State private var newItem: String = ""
    @State private var showingAddSheet: Bool = false
    @State private var showingEditSheet: Bool = false
    @State private var showingEdit2Sheet: Bool = false
    @State private var selectedItem: GroceryItem? = nil
    @State private var editText: String = ""
    @State private var duplicateItemAlert: Bool = false
    @State private var selectedTab: Int = 1
    @State private var ingredients: [ingredient] = []
    @State private var prompt: String = "";
    
    var body: some View {
        TabView(selection: $selectedTab) {
            RecipeView(ingredients: $ingredients, editIngredientsSheet: $showingEditSheet, editPromptSheet: $showingEdit2Sheet, prompt: $prompt )
                .tabItem {
                    Label("Recipes", systemImage: "frying.pan")
                }
                .tag(1)
            
            
            GroceryListView(
                groceries: $groceries,
                showingAddSheet: $showingAddSheet,
                selectedItem: $selectedItem,
                duplicateItemAlert: $duplicateItemAlert,
                addItem: addItem,
                editItem: editItem,
                deleteItem: deleteItem,
                togglePurchased: togglePurchased
            )
            .tabItem {
                Label("List", systemImage: "list.dash")
            }
            .tag(0)
        }
        .onAppear {
            loadGroceries()
//            testTokenizer()
        }
        .alert(isPresented: $duplicateItemAlert) {
            Alert(title: Text("Duplicate Item"), message: Text("This item already exists in the list."), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $showingAddSheet) {
            AddItemSheet(newItem: $newItem, addItem: addItem)
        }
        .sheet(item: $selectedItem) { item in
            EditItemSheet(editText: $editText, saveEditedItem: { saveEditedItem(item) })
                .onAppear { editText = item.name }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditIngredientsSheet(editText: $editText, ingredients: $ingredients)
        }.sheet(isPresented: $showingEdit2Sheet
        ) {
            EditPromptSheet(prompt: $prompt)
        }
    }

    func deleteItem(at offsets: IndexSet) {
        groceries.remove(atOffsets: offsets)
        saveGroceries()
    }

    func editItem(_ item: GroceryItem) {
        selectedItem = item
    }

    func saveEditedItem(_ item: GroceryItem) {
        if let index = groceries.firstIndex(where: { $0.id == item.id }), !editText.isEmpty {
            groceries[index].name = editText
            saveGroceries()
            selectedItem = nil
        }
    }

    func addItem() {
        let trimmedItem = newItem.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedItem.isEmpty { return }
        if groceries.contains(where: { $0.name.lowercased() == trimmedItem.lowercased() }) {
            duplicateItemAlert = true
            return
        }
        groceries.append(GroceryItem(name: trimmedItem))
        saveGroceries()
        newItem = ""
        showingAddSheet = false
    }

    func togglePurchased(_ item: GroceryItem) {
        if let index = groceries.firstIndex(where: { $0.id == item.id }) {
            groceries[index].purchased.toggle()
            saveGroceries()
        }
    }

    func saveGroceries() {
        if let encoded = try? JSONEncoder().encode(groceries) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    func loadGroceries() {
        if let savedData = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([GroceryItem].self, from: savedData) {
            groceries = decoded.filter { !$0.purchased }
        }
    }
//    func testTokenizer() async throws {
//        let tokenizer = try await AutoTokenizer.from(pretrained: "deepseek-ai/DeepSeek-R1-Distill-Qwen-7B")
//        let messages = [["role": "user", "content": "Describe the Swift programming language."]]
//        let encoded = try tokenizer.applyChatTemplate(messages: messages)
//        let decoded = tokenizer.decode(tokens: encoded)
//        
//        print(decoded)
//    }
    
//    'func testTokenizer() {
//        let semaphore = DispatchSemaphore(value: 0)
//
//        Task {
//            let tokenizer = try await AutoTokenizer.from(pretrained: "deepseek-ai/DeepSeek-R1-Distill-Qwen-7B")
//            let messages = [["role": "user", "content": "Describe the Swift programming language."]]
//            let encoded = try tokenizer.applyChatTemplate(messages: messages)
//            let decoded = tokenizer.decode(tokens: encoded)
//
//            print(decoded)
//            semaphore.signal()
//        }
//
//        semaphore.wait()
//    }

}

// MARK: - Grocery List View
struct GroceryListView: View {
    @Binding var groceries: [GroceryItem]
    @Binding var showingAddSheet: Bool
    @Binding var selectedItem: GroceryItem?
    @Binding var duplicateItemAlert: Bool

    var addItem: () -> Void
    var editItem: (GroceryItem) -> Void
    var deleteItem: (IndexSet) -> Void
    var togglePurchased: (GroceryItem) -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(groceries) { item in
                    GroceryItemRow(item: item, togglePurchased: togglePurchased)
                        .swipeActions(edge: .leading) {
                            Button {
                                editItem(item)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                }
                .onDelete(perform: deleteItem)
            }
            .navigationTitle("Grocery List")
            .toolbar {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
//        .onAppear {
//                do {
//                    let config = MLModelConfiguration()
//                    let model = try gpt2_512(configuration: config)
//                    
//                    let input = "Hello, how are you?"
//                    let tokenizedInput = tokenize(input) // Tokenize the input text
//                    let output = try? model.prediction(input: tokenizedInput)
//                    let generatedText = detokenize(output) // Convert tokens back to text
//                    print(generatedText)
//                    // Use the model for predictions
//                } catch {
//                    print("Error loading model: \(error)")
//                }
//        }
    }
}

// MARK: - Grocery Item Row
struct GroceryItemRow: View {
    var item: GroceryItem
    var togglePurchased: (GroceryItem) -> Void

    var body: some View {
        HStack {
            Text(item.name)
                .strikethrough(item.purchased, color: .gray)
                .foregroundColor(item.purchased ? .gray : .primary)
            
            Spacer()
            
            Button {
                togglePurchased(item)
            } label: {
                Image(systemName: item.purchased ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.purchased ? .green : .gray)
            }
        }
    }
}

struct RemoteImageView: View {
    let imageUrl: URL

    var body: some View {
        AsyncImage(url: imageUrl) { phase in
            switch phase {
            case .empty:
                ProgressView() // Loading indicator
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
            case .failure:
                Image(systemName: "photo") // Fallback image
            @unknown default:
                EmptyView()
            }
        }
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct recipeItemView: View {
    @Binding var recipe: Recipe
    var update: (Recipe) -> Void;
    
    @State private var isShareSheetPresented = false
    @State private var activityItems: [Any] = []
    @State private var isLoading = false

    var body: some View {
        VStack {
            // Main Image
            ZStack(alignment: .bottom) {
                RemoteImageView(imageUrl: URL(string: recipe.image)!)
                    .frame(width: 296, height: 224)

                // Fade effect
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black.opacity(0.6)]),
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(width: 296, height: 100)
            }
            .cornerRadius(8)

            // Recipe Info
            VStack(alignment: .leading, spacing: 8) {
                Text(recipe.title)
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text(recipe.shortDescription)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack {
                    Label(recipe.time, systemImage: "clock")
                    Spacer()
                    Label(recipe.difficulty, systemImage: "flame")
                    Spacer()
                    
                    Button(action: {
                        shareRecipe()
                    }) {
                        Image(systemName: isLoading ? "hourglass" : "square.and.arrow.up")
                    }
                    .disabled(isLoading)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }.onTapGesture {
                update(recipe)
            }
            .frame(width: 296)
            .padding()
            .cornerRadius(8)

            Spacer()
        }
        .sheet(isPresented: $isShareSheetPresented) {
            ActivityView(activityItems: activityItems)
        }
    }

    private func shareRecipe() {
        isLoading = true

        guard let imageURL = URL(string: recipe.image) else {
            print("Invalid image URL")
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: imageURL) { data, response, error in
            defer { isLoading = false }

            guard let data = data, let image = UIImage(data: data) else {
                print("Failed to load image")
                return
            }

            let longText = """
            \(recipe.title)

            \(recipe.shortDescription)

            Ingredients:
            \(recipe.ingredients.map { "• \($0)" }.joined(separator: "\n"))

            Steps:
            \(recipe.steps.map { "• \($0)" }.joined(separator: "\n"))
            """

            activityItems = [longText, image]
            print("success")
            isShareSheetPresented = true
        }.resume()
    }
}

struct actionItems: View {
    @Binding var editIngredientsSheet: Bool
    @Binding var editPromptSheet: Bool
    
    var body: some View {
        HStack {
            Button("Set ingredients") {
                editIngredientsSheet = true
            }
            .buttonStyle(.bordered)
            .cornerRadius(13)
            .padding()
            .font(.title2)

            Button("Add a prompt") {
                editPromptSheet = true
            }
            .buttonStyle(.bordered)
            .cornerRadius(13)
            .padding()
            .font(.title2)
        }
        .padding()
    }
}


// MARK: - Recipe View
struct RecipeView: View {
    @Binding var ingredients: [ingredient]
    @Binding var editIngredientsSheet: Bool
    @Binding var editPromptSheet: Bool
    @Binding var prompt: String

    @State var path = NavigationPath()
    @State var recipes: [Recipe] = [Recipe(title: "Creamy Pasta Rose", shortDescription: " luscious and comforting pasta dish with a beautiful pink sauce made from a blend of tomato and cream.", ingredients: ["200g pasta (penne or spaghetti)","1 cup tomato sauce","1/2 cup heavy cream","2 cloves garlic, minced","1 tablespoon olive oil","Salt and pepper to taste","Grated Parmesan cheese (optional)","Fresh basil leaves (for garnish)"], steps: ["Cook the pasta in boiling salted water according to package instructions until al dente. Drain and set aside.","In a large skillet, heat the olive oil over medium heat. Add minced garlic and sauté until fragrant, about 1 minute.","Pour in the tomato sauce and cook for 2-3 minutes, stirring occasionally.","Add the heavy cream to the tomato sauce, stirring well to combine. Cook for another 2-3 minutes until the sauce is heated through and turns a lovely pink color.","Season with salt and pepper to taste.","Add the cooked pasta to the skillet and toss to coat evenly with the sauce.","Serve hot, garnished with grated Parmesan cheese and fresh basil leaves if desired."], difficulty: "Easy", time: "20 min", image: "https://api.together.ai/imgproxy/vNTK87K2QglAfUz-yX9Mt0BHdR7FVgzwIlPd-u3FwHQ/format:jpeg/aHR0cHM6Ly90b2dldGhlci1haS1iZmwtaW1hZ2VzLXByb2QuczMudXMtd2VzdC0yLmFtYXpvbmF3cy5jb20vaW1hZ2VzL2VlYmUyNjdlYWYwMDIzN2JjYzgzOWZiMzI1MjExNjNjMzljMWI0ZTFiMTBmNTA1MmQ4ODk4OWY0Y2RjNTA3YjQ_WC1BbXotQWxnb3JpdGhtPUFXUzQtSE1BQy1TSEEyNTYmWC1BbXotQ29udGVudC1TaGEyNTY9VU5TSUdORUQtUEFZTE9BRCZYLUFtei1DcmVkZW50aWFsPUFTSUFZV1pXNEhWQ04yRTc3RjVQJTJGMjAyNTA0MTUlMkZ1cy13ZXN0LTIlMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjUwNDE1VDIxNDUwOVomWC1BbXotRXhwaXJlcz0zNjAwJlgtQW16LVNlY3VyaXR5LVRva2VuPUlRb0piM0pwWjJsdVgyVmpFSzclMkYlMkYlMkYlMkYlMkYlMkYlMkYlMkYlMkYlMkZ3RWFDWFZ6TFhkbGMzUXRNaUpITUVVQ0lIOE5Zang1YVNFamZlYTV4Y1RVYlkyNnZlZlNQWWw1ZzlsV0NsUkQxaUNYQWlFQXJvZSUyRll6a2JnSyUyQkhvZ1ViQWNkMlNrUTRZbkRlbkhPV2JKRjBObnROVHpzcWtBVUlOeEFBR2d3MU9UZzNNall4TmpNM09EQWlEQzYwNW5BdkM0bnUlMkZTZ09TeXJ0QklNSTVwYkNmQSUyQm11QWx6dVNUa0ZYaVJsT3R0MkIwcURTbCUyRldhYTZ4TDhSZVVMOVV5JTJGbVFVRFB0NSUyQm5zMFlBM0FuMGwlMkJ2NTVielpuYyUyQkhHd3duRHg1Y1o0c2lxZ2phVFZES1hpRWVwWEx2Z29UaFhuTGpzTGI5YVI1a3ZsbGYxVTFLRTlITndvMjFwTVNzRGJJdXR3cnF4UXFsUzZFa3M5WVlWaVJVV2pqMWJoamJyRUxtSXdUWGk4dmhPR09OTzNOUUN3WnMwRjNmY3NyUWZzUHdoWDZjcVdkMjd0MFVJVjNXMFMlMkZVVnBpelFWJTJCZFppQ2tTRmxtYTlTWXhrNVFUbzQzUjJNZGZQcU1YMURUNFdDQzBxQjBuOVJsVE5QWE1yRlYxUHoyQnU0M0kzbkh0Vms5ZmpUakN0cFpRanphayUyRlFUcE9JaHZ1NGNzeWxKYzR2YnJxSktZU3dzZEwlMkJJU2FnMEZpNHQ5TXl5R2FlcUFXUUphcXQ4c1N6a0o2MVJ5bWdrVE8wUDVaWU9ubTRIY3BXRWw0SFFQRVN1OU9majYlMkJjY2NrRDclMkJDYjBVeHdzZFQ1b0g4SXg4VzY3N2hQN0VSSEplWmtBSlNpbmQ0YjRreWhsZGNmbmVTVzREdVhlVmJtaWMxRTZIUCUyQnglMkZLYkZQNmpyVUg4RGxsZUdiJTJGaVJOQW5CZTV0VHBSVTlwczFzRDVFOFVxYU9qeVI0b25Qb0V5WmFNSHVIb1dMMFhjTnBkY2MwTm43QklmRllpZHU3YzV2eGtmN00xUE9PYzdXRGVqU29QaWJoaHFxT0ZpRk1IYmtEZGhZQlZJUlJVYiUyQmFrZ2hJcWhNeXVodk4yUE9yNEhpakdmQkY4MUYzUGdnUGV4TUloYnVaUWxJZ3NJUzJMVm9pWkpiSFNwMzl5NENySyUyQjVpZ2U3OWdJVFFVcVJ3YThFMXBkV3JNaUwlMkZLOEpiQnZwS0lTZGd2N0JpUlAyJTJGdlNKaUNBbU5qc1pQeE1NYjlNcFJjRGRUaURXb2U1dWpCemJlVVpUSUhJV21rbnl6WEtNUXpZZU5zRWpyJTJGUFBPcjdxRHlCU2JoaW5pM0xmVk4lMkJUOTNmMyUyRkxucWFJekRscHZ1JTJGQmpxYkFTU1NrT3Z3VllwaEFvOXVxbkExTm9oZWJyOUVuRCUyQiUyQmFGSmVBSyUyRjdwNkJtMGRVTGdrcDVRSW1OZ3M5Y0VKJTJCRERSR0dKa3JTcE5OZ296VjNYdmZMbEVLczV3QjB0RjMwc1hsUlEzREhEQkExTCUyRklZWEozN2ttZkUlMkJ0VkFkSXdudmdxTjVwbzdWZHdnVFFIcGNPMjJvdUVOaDM4bUdoaVhHZzB5R2VmdDNhbjBMaTllSSUyRm9nQVBOM0FTR2tLJTJCRFZudE1UT1ZXUiUyQkJIWlBrZ0wmWC1BbXotU2lnbmF0dXJlPTZiMzFlOWRiZjQ2YmY0ZmQxYTg5ODAyMDgzMzQzOWYzYzE4OTQ3MTljZGU2YTExZDFkMzllODliMDhmMmZmMjMmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0JngtaWQ9R2V0T2JqZWN0"
)]
    
    @State var genNum = 0 // ensure generation is different
    
    func changeView(recipe: Recipe) {
        path.append(recipe)
    }


    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack {
                    actionItems(editIngredientsSheet: $editIngredientsSheet, editPromptSheet: $editPromptSheet)

                    ForEach($recipes) { recipe in
                        recipeItemView(recipe: recipe, update: changeView).navigationDestination(for: Recipe.self) {recipe in
                            insideRecipeView(recipe: recipe)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Recipes")
        }
        .onAppear {
            fetchRecipes()
        genNum+=1;
            fetchRecipes(replaceList: false) // fetch 2 for good measure
        }
        .onChange(of: ingredients) {
            fetchRecipes()
        genNum+=1;
            fetchRecipes(replaceList: false) // fetch 2 for good measure
        }.onChange(of: prompt) {
        genNum+=1;
            fetchRecipes()
        genNum+=1;
            fetchRecipes(replaceList: false) // fetch 2 for good measure
        }
    }

    private func fetchRecipes(replaceList: Bool = true) {
        
        guard var url = URL(string: "https://searchbuddy.app/api/createRecipe") else {
            print("Invalid URL")
            return
        }

        if ingredients.count > 0 {
            let item = URLQueryItem(name: "ingredients", value: ingredients.map(\.name).joined(separator: ", "))
            url.append(queryItems: [item])
        }
        
        if prompt.lengthOfBytes(using: .utf8) > 0 {
            let item = URLQueryItem(name: "q", value: "num: \(genNum) [IGNORE].   \(prompt)")
            url.append(queryItems: [item])
        } else {
            let item = URLQueryItem(name: "q", value: "num: \(genNum) [IGNORE]")
            url.append(queryItems: [item])
        }
        
        
        

        print("Fetching with ingredients: \(ingredients)")

        var request = URLRequest(url: url)
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120

        let session = URLSession(configuration: config)

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Error: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("✅ Status Code: \(httpResponse.statusCode)")
            }

            if let data = data {
                do {
                    print(String(data: data, encoding: .utf8) ?? "No data")
                    let decodedRecipe = try JSONDecoder().decode(Recipe.self, from: data)
                    DispatchQueue.main.async {
                        if(replaceList)
                        {
                            recipes = []
                        }// Replace old recipes
                        recipes.append(decodedRecipe)
                            
                        print("Updated recipes: \(recipes)")
                    }
                } catch {
                    print("Failed to decode recipes: \(error)")
                }
            }
        }
        task.resume()
    }
}

// MARK: - Add Item Sheet
struct AddItemSheet: View {
    @Binding var newItem: String
    var addItem: () -> Void

    var body: some View {
        VStack {
            Text("Enter new item")
                .font(.headline)
                .padding()

            TextField("Item Name", text: $newItem)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            HStack {
                Button("Cancel") {
                    newItem = ""
                }
                .padding()

                Button("Add") {
                    addItem()
                }
                .padding()
                .disabled(newItem.isEmpty)
            }
        }
        .padding()
    }
}

// MARK: - Edit Item Sheet
struct EditItemSheet: View {
    @Binding var editText: String
    var saveEditedItem: () -> Void

    var body: some View {
        VStack {
            Text("Edit item")
                .font(.headline)
                .padding()

            TextField("Edit Item", text: $editText)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            HStack {
                Button("Cancel") { }
                    .padding()

                Button("Save") {
                    saveEditedItem()
                }
                .padding()
                .disabled(editText.isEmpty)
            }
        }
        .padding()
    }
}

// MARK: - Edit Ingredients Sheet
struct EditIngredientsSheet: View {
    @Binding var editText: String
    @Binding var ingredients: [ingredient]
//    var saveItems: () -> Void
    func deleteIngredient(at offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
    }

    var body: some View {
        VStack {
            List {
                ForEach(ingredients) { ingredient in
                    Text(ingredient.name)
                        .font(.caption)
                        .padding()
                }
                .onDelete(perform: deleteIngredient)
//                .onDelete(perform: deleteIngredient)
            }
            Text("Add ingredient")
                .font(.headline)
                .padding()

            TextField("Add ingredient", text: $editText)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            HStack {
                Button("Save") {
//                    saveEditedItem()
                    ingredients.append(ingredient(name: editText))
                }
                .padding()
                .disabled(editText.isEmpty)
            }
        }
        .padding()
    }
}

// MARK: - Edit Prompt Sheet
struct EditPromptSheet: View {
    @Binding var prompt: String;

    @State private var editText: String;
    
    init(prompt: Binding<String>) {
        self._prompt = prompt
        self._editText = State(initialValue: prompt.wrappedValue)
    }

    var body: some View {
        VStack {
            Text("Add Prompt")
                .font(.headline)
                .padding()

            TextField("Add ingredient", text: $editText)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            HStack {
                Button("Save") {
//                    saveEditedItem()
                    prompt = editText;
                }
                .padding()
                .disabled(editText.isEmpty)
            }
        }
        .padding()
    }
}


struct InsideRecipeItemItem: Identifiable {
    let id = UUID()
    var name: String
    var used: Bool = false
}


struct InsideRecipeItem: View {
    var name: String
    @Binding var used: Bool

    var body: some View {
        HStack {
            Image(systemName: used ? "checkmark.circle.fill" : "circle")
                .onTapGesture {
                    used.toggle()
                }
            Text(name)
//                .foregroundColor(.primary)
                .foregroundColor(used ? .gray : .primary)
                .strikethrough(used, color: .black)
            
        }
    }
}



struct insideRecipeView: View {
    var recipe: Recipe
    
    @State private var isLoading: Bool = false;
    @State private var isShareSheetPresented = false
    @State private var activityItems: [Any] = []

    @State private var ingredientItems: [InsideRecipeItemItem] = []
    @State private var stepItems: [InsideRecipeItemItem] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let url = URL(string: recipe.image) {
                    RemoteImageView(imageUrl: url)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .foregroundColor(.gray)
                        .padding()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(recipe.shortDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                HStack {
                    Label(recipe.difficulty, systemImage: "flame")
                    Spacer()
                    Label(recipe.time, systemImage: "clock")
                    Spacer()
                    Button("Share", systemImage: "square.and.arrow.up") {
                        shareRecipe()
                    }
                }
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Ingredients")
                        .font(.title2)
                        .fontWeight(.semibold)

                    ForEach($ingredientItems) { $item in
                        InsideRecipeItem(name: item.name, used: $item.used)
                    }
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Instructions")
                        .font(.title2)
                        .fontWeight(.semibold)

                    ForEach($stepItems) { $item in
                        InsideRecipeItem(name: item.name, used: $item.used)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .navigationTitle("Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            ingredientItems = recipe.ingredients.map { InsideRecipeItemItem(name: $0) }
            stepItems = recipe.steps.map { InsideRecipeItemItem(name: $0) }
        }.sheet(isPresented: $isShareSheetPresented) {
            ActivityView(activityItems: activityItems)
        }
    }
    
    private func shareRecipe() {
        isLoading = true

        guard let imageURL = URL(string: recipe.image) else {
            print("Invalid image URL")
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: imageURL) { data, response, error in
            defer { isLoading = false }

            guard let data = data, let image = UIImage(data: data) else {
                print("Failed to load image")
                return
            }

            let longText = """
            \(recipe.title)

            \(recipe.shortDescription)

            Ingredients:
            \(recipe.ingredients.map { "• \($0)" }.joined(separator: "\n"))

            Steps:
            \(recipe.steps.map { "• \($0)" }.joined(separator: "\n"))
            """

            activityItems = [longText, image]
            print("success")
            isShareSheetPresented = true
        }.resume()
    }
}

#Preview {
    ContentView()
}



#include <iostream>
#include <string>
using namespace std;
class Item {
private:
    string name;
    int barcode;
    float price;
    int quantity;
public:

    Item(string n="", int b=0, float p=0.0, int q=0) {
        this->name = n;
        this->barcode = b;
        this->price = p;
        this->quantity = q;
    }
    void changeItemName(string n) {
        name = n;
    }
    void changeItemPrice(float p) {
        price = p;
    }
    void addquantity(int n) {
        quantity += n;
    }

    string getname() {
        return name;
    }
    int getBarcode() {
        return barcode;
    }
    float getPrice()
    {
        return price;
    }
    int getQuantity() {
        return quantity;
    }

    void printItems() {
        cout << "Item: " << name << endl;
        cout << "Barcode: " << barcode << endl;
        cout << "Price: " << price << endl;
        cout << "Quantity: " << quantity << endl;
    }
};
class Inventory {
    Item* items;
    int size;
public:
    Inventory() {
        items = nullptr;
        size = 0;
    }

    ~Inventory() {
        delete[] items;
    }
    void addItems( Item& a) {
        for (int i = 0; i < size; i++) {
            if (items[i].getBarcode() == a.getBarcode()) {
                items[i].addquantity(a.getQuantity());
                return;
            }
        }
        Item* temp = new Item[size + 1];
        for (int i = 0; i < size; i++) {
            temp[i] = items[i];
        }
        temp[size] = a;
        delete[] items;
        items = temp;
        size++;

    }
    void deleteItems(int barcode){
        int index = -1;
        for (int i = 0; i < size; i++) {
            if (items[i].getBarcode() == barcode) {
                index = i;
                break;
            }
        }
        if (index == -1) {
            cout << "Item not found with barcode " << barcode << endl;
            return;
        }
        Item* temp = new Item[size - 1];
        int j = 0;
        for (int i = 0; i < size;i++) {
            if (i != index) {
                temp[j] = items[i];
                j++;
            }
        }
        delete[] items;
        items = temp;
        size--;
    }
    void PrintInventory() {
        if (size == 0) {
            cout << "Invventory is empty. " << endl;
            return;
        }
        for (int i = 0; i < size; i++) {
            cout << "-------------------" << endl;
            items[i].printItems();
        }
        
    }
    Item* getItems() {
        return items;
    }
    int getsize() {
        return size;
    }
};
class order {
    Item* items;       
    int* quantities;   
    int size;
    float preTaxPrice;
    float tax;
    float totalPrice;
    string paymentMethod;  
    string status;         
public:
    order() {
        items = nullptr;
        quantities = nullptr;
        size = 0;
        preTaxPrice = 0;
        tax = 0;
        totalPrice = 0;
        paymentMethod = "Not set";
        status = "Pending";
    }
    ~order() {
        delete[]items;
        delete[] quantities;
    }

    void addItemInOrder(Item& newitem, int q) {
        for (int i=0; i<size; i++){
            if (items[i].getBarcode() == newitem.getBarcode()) {
                quantities[i] += q;
                return;
            }
        }
        Item* tempItems = new Item[size + 1];
        int* tempQuantities = new int[size + 1];

        for (int i = 0; i < size; i++) {
            tempItems[i] = items[i];
            tempQuantities[i] = quantities[i];
        }
        int newindex = size;
        size++;
        tempItems[newindex] = newitem;
        tempQuantities[newindex] = q;
        
        delete[] items;
        delete[] quantities;

        items = tempItems;
        quantities = tempQuantities;
        
    }
    void removeItemFromOrder(int code) {
        int index = -1;
        for (int i = 0; i < size; i++) {
            if (items[i].getBarcode() == code) {
                index = i;
                break;
            }
        }
        if (index == -1) {
            cout << "Item not found in order" << endl;
            return;
        }

        Item* tempItems = new Item[size - 1];
        int* tempQuantities = new int[size - 1];
        int j = 0;
        for (int i = 0; i < size; i++) {
            if (i != index) {
                tempItems[j] = items[i];
                tempQuantities[j] = quantities[i];
                j++;
            }
        }

        delete[] items;
        delete[] quantities;

        items = tempItems;
        quantities = tempQuantities;
        size--;
    }
    void calculateBill(string method) {
        paymentMethod = method;
        preTaxPrice = 0;

        for (int i = 0; i < size; i++) {
            preTaxPrice += items[i].getPrice() * quantities[i];
        }

        if (paymentMethod == "Cash" || paymentMethod == "cash") {
            tax = preTaxPrice * 0.15;
        }
        else if (paymentMethod == "Card" || paymentMethod == "card") {
            tax = preTaxPrice * 0.05;        }
        else {
            tax = 0;
        }

        totalPrice = preTaxPrice + tax;
        status = "Completed";
    }
    void printOrderDetails() {
        cout << "========ORDER DETAIILS=========" << endl;
        for (int i = 0; i < size; i++) {
            cout << "---------------------------" << endl;
            cout << "Title: " << items[i].getname() << endl;
            cout << "Quantity: " << quantities[i] << endl;
            cout << "Price per unit: " << items[i].getPrice() << endl;
            cout << "---------------------------" << endl;
        }
        cout << "Pre-Tax Price: " << preTaxPrice << endl;
        cout << "Tax " << tax << endl;
        cout << "Total Price: " << totalPrice << endl;
        cout << "Payment Method: " << paymentMethod << endl;
        cout << "Status: " << status << endl;
    }
    float getTotalPrice() {
        return totalPrice;
    }
    string getStatus() {
        return status;
    }
};

struct OrderHistoryNode {
    order* Order;
    OrderHistoryNode* next;
    OrderHistoryNode(order* o) {
        Order = o;
        next = NULL;
    }

};
class OrderHistoryLinklist {
    OrderHistoryNode* head;
public:
    OrderHistoryLinklist() {
        head = NULL;
    }

    void addOrder(order* o) {
        if (o->getStatus() != "Completed") {
            cout << "Order is not completed yet!" << endl;
            return;
        }
        OrderHistoryNode* newnode = new OrderHistoryNode(o);
        if (head == NULL) {
            head = newnode;
        }
        else {
            OrderHistoryNode* temp = head;
            while (temp->next != NULL) {
                temp = temp->next;
            }
            temp->next = newnode;
        }
    }
    void removeOrder(float total){
        if (head == NULL) {
            cout << "Failed! there is no order in the list!" << endl;
            return;
        }
        OrderHistoryNode* temp = head;
        OrderHistoryNode* pre = NULL;
        while (temp != NULL && temp->Order->getTotalPrice() != total) {
            pre = temp;
            temp = temp->next;
        }
        if (temp == NULL) {
            cout << "Order not Found!" << endl;
            return;
        }
        if (pre == NULL) {
            head = temp->next;
        }else{
            pre->next = temp->next;
        }
        delete temp;
        cout << "Order removed from list" << endl;
    }
    void printOrderHistory() {
        if (head == NULL) {
            cout << "No Order is in List" << endl;
            return;
        }
        OrderHistoryNode* temp = head;
        while (temp != NULL) {
            cout << "==========Order from list==========" << endl;
            temp->Order->printOrderDetails();
            cout << "-----------------------------------" << endl;
            temp = temp->next;
        }
    }
};

class store {
    Inventory inventory;
    order** PendingOrders;
    OrderHistoryLinklist History;
    int penorderCount;
    float TotalRevenue;
public:
    store() {
        PendingOrders = nullptr;
        penorderCount = 0;
        TotalRevenue = 0.0;
    }
    ~store() {
        for (int i = 0; i < penorderCount;i++) {
            delete PendingOrders[i];
        }
        delete[] PendingOrders;
    }
    Inventory& getInventory() {
        return inventory;
    }
    order* createOrder() {
        order* neworder = new order();
        order** temp = new order * [penorderCount + 1];
        for (int i = 0; i < penorderCount;i++) {
            temp[i] = PendingOrders[i];
        }
        temp[penorderCount] = neworder;
        delete[] PendingOrders;
        PendingOrders = temp;
        cout << "New Order created Pending." << endl;
        penorderCount++;
        return neworder;
    }

    void deleteOrder(order* o) {
        int index = -1;
        for (int i = 0; i < penorderCount;i++) {
            if (PendingOrders[i] == o) {
                index = i;
                break;
            }
        }
        if (index == -1) {
            cout << "Order not found!" << endl;
            return;
        }
        delete PendingOrders[index];
        order** temp = new order * [penorderCount - 1];
        int j = 0;
        for (int i = 0; i < penorderCount ;i++) {
            if (i != index) {
                temp[j] = PendingOrders[i];
                j++;
            }
        }
        delete[] PendingOrders;
        PendingOrders = temp;
        penorderCount--;
        cout << "pending Order Removed." << endl;
    }
    void detachOrder(order* o) {
        int index = -1;
        for (int i = 0; i < penorderCount; i++) {
            if (PendingOrders[i] == o) {
                index = i;
                break;
            }
        }
        if (index == -1) {
            cout << "Order not found!" << endl;
            return;
        }

        order** temp = new order * [penorderCount - 1];
        int j = 0;
        for (int i = 0; i < penorderCount; i++) {
            if (i != index) {
                temp[j++] = PendingOrders[i];
            }
        }

        delete[] PendingOrders;
        PendingOrders = temp;
        penorderCount--;

        cout << "Order detached from pending list." << endl;
    }
    void completeOrder(order* o, string method) {
        o->calculateBill(method);
        TotalRevenue += o->getTotalPrice();
        detachOrder(o);
        History.addOrder(o);
        cout << "Order Completed and add to the history list" << endl;
    }
    void printPendingOrders() {
        if (penorderCount == 0) {
            cout << "No pending orders." << endl;
            return;
        }

        for (int i = 0; i < penorderCount; i++) {
            cout << "===== Pending Order " << (i + 1) << " =====" << endl;
            PendingOrders[i]->printOrderDetails();
            cout << "---------------------------" << endl;
        }
    }
    void sortPendingOrder(bool ascending) {
        if (penorderCount == 0) {
            cout << "NO pending order to sort" << endl;
            return;
        }
        for (int i = 0; i < penorderCount-1;i++) {
            for (int j = 0; j < penorderCount - i - 1;j++) {
                if (ascending) {
                    if (PendingOrders[j]->getTotalPrice() > PendingOrders[j + 1]->getTotalPrice()) {
                        order* temp = PendingOrders[j];
                        PendingOrders[j] = PendingOrders[j + 1];
                        PendingOrders[j + 1] = temp;
                    }
                }
                else
                {
                    if (PendingOrders[j]->getTotalPrice() < PendingOrders[j + 1]->getTotalPrice()) {
                        order* temp = PendingOrders[j];
                        PendingOrders[j] = PendingOrders[j + 1];
                        PendingOrders[j + 1] = temp;
                    }
                }
            }
        }
        printPendingOrders();
    }
    int getPendingCount() {
        return penorderCount;
    }
    order* getPendingOrder(int index) {
        return PendingOrders[index];
    }
    void printHistory() {
        History.printOrderHistory();
    }
    void calculateRevenue() {
        cout << "Total Renvenue: " << TotalRevenue << endl;
    }
};

int main(){
    store s;
    int choice;
    do {
        cout << "========== MAIN MENU ==========" << endl;
        cout << "1. Add Item to Inventory" << endl;
        cout << "2. Print Inventory" << endl;
        cout << "3. Create New Order" << endl;
        cout << "4. Modify Existing Pending Order" << endl;
        cout << "5. Complete an Order" << endl;
        cout << "6. Cancel a Pending Order" << endl;
        cout << "7. Print Pending Orders" << endl;
        cout << "8. Print Sorted Pending Orders" << endl;
        cout << "9. Print Orders History" << endl;
        cout << "10. Show Total Revenue" << endl;
        cout << "0. Exit" << endl;
        cout << "Select an option: " << endl;
        cin >> choice;
        if (choice < 0 || choice > 10)
        {
            cout << "Enter valid Optoin!" << endl;
            cout << "Re-Enter: ";
            continue;
        }
        if (choice == 1) {
            string name;
            int barcode, quantity;
            float price;
            cout << "Enter Item Name: ";
            cin >> name;
            cout << "Enter Barcode: ";
            cin >> barcode;
            cout << "Enter Price: ";
            cin >> price;
            cout << "Enter Quantity: ";
            cin >> quantity;
            Item a(name, barcode, price, quantity);
            s.getInventory().addItems(a);
        }
        else if (choice == 2) {
            s.getInventory().PrintInventory();
        }
        else if (choice == 3) {
            s.createOrder();
        }
        else if (choice == 4) {
            s.printPendingOrders();
            int orderindex;
            cout << "Select order number to modify!";
            cin >> orderindex;
            if (orderindex <= 0 || orderindex > s.getPendingCount()) {
                cout << "Invalid Order Number!" << endl;
                continue;
            }
            order* selectedOrder = s.getPendingOrder(orderindex - 1);
            int subchoice;
            cout << "1.Add Item to order" << endl;
            cout << "2.Remove Item from order" << endl;
            cin >> subchoice;
            if (subchoice == 1) {
                int barcode, qty;
                cout << "Enter Item Barcode: ";
                cin >> barcode;
                cout << "Enter Quantity: ";
                cin >> qty;
                bool found = false;
                for (int i = 0; i < s.getInventory().getsize(); i++) {
                    Item* items = s.getInventory().getItems();
                    if (items[i].getBarcode() == barcode) {
                        selectedOrder->addItemInOrder(items[i], qty);
                        found = true;
                        break;
                    }
                }
                if (!found) cout << "Item not found in inventory!"<<endl;
            }
            else if (subchoice == 2) {
                int barcode;
                cout << "Enter Item Barcode to remove: ";
                cin >> barcode;
                selectedOrder->removeItemFromOrder(barcode);
            }

        }
        else if (choice == 5) {
            s.printPendingOrders();
            int orderIndex;
            cout << "Select order number to complete: ";
            cin >> orderIndex;

            if (orderIndex <= 0 || orderIndex > s.getPendingCount()) {
                cout << "Invalid order number!"<<endl;
                continue;
            }

            string payment;
            cout << "Enter Payment Method (Cash/Card): ";
            cin >> payment;

            order* selectedOrder = s.getPendingOrder(orderIndex - 1);
            s.completeOrder(selectedOrder, payment);
        }
        else if (choice == 6) {
            s.printPendingOrders();
            int orderIndex;
            cout << "Select order number to cancel: ";
            cin >> orderIndex;

            if (orderIndex <= 0 || orderIndex > s.getPendingCount()) {
                cout << "Invalid order number!"<<endl;
                continue;
            }

            order* selectedOrder = s.getPendingOrder(orderIndex - 1);
            s.deleteOrder(selectedOrder);
        }
        else if(choice == 7) {
            s.printPendingOrders();
        }
        else if (choice == 8) {
            int sortchoice;
            cout << "1.Assending" << endl;
            cout << "2.Decending" << endl;
            cin >> sortchoice;
            s.sortPendingOrder(sortchoice == 1);
        }
        else if (choice == 9) {
            s.printHistory();
        }
        else if (choice == 10) {
            s.calculateRevenue();
        }
        else if (choice == 0) {
            cout << "Exitting program !" << endl;
        }
        else {
            cout << "invalid Choice!" << endl;
        }
        


        
    } while (choice!=0);

}

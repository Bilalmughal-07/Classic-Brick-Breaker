

#include <iostream>
using namespace std;



struct node {
    int val;
    node* next;
    node() {
        next = NULL;
    }
    node(int val) {
        next = NULL;
        this-> val=val;
    }
      

};
class linklist {
    node* start;
public:
    linklist() {
        start = NULL;

    }
    
    void insertend(int val)
    {
        node* endnode = new node(val);
        if (endnode == NULL)
        {
            cout << "node not created!" << endl;
        }
        else {
            if (start == NULL)
            {
                start = endnode;
            }
            else {
                node* temp = start;
                ;
                while (temp->next != NULL)
                {
                    temp = temp->next;
                }
                temp->next = endnode;

            }
           
        }
    }
    void display()
    {
        node* temp = start;
        while (temp != NULL)
        {
            cout << temp->val << " ";
            temp = temp->next;
        }
        cout << endl;
    }
       
};
int main()
{
    linklist li;
    li.insertend(1);
    li.insertend(3);
    li.insertend(4);
    li.insertend(7);
    cout << "Linked List: ";
    li.display();

    return 0;
}


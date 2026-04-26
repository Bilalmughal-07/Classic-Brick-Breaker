
#include <iostream>
using namespace std;

struct node {
	int data;
	node* next;
	node(int val) {
		data = val;
		next = NULL;
	}
};
class linklist {
	node* start;
public:
	linklist() {
		start = NULL;
	}
	
	void insertnode_atend(int val) {
		node* newnode = new node(val);
		if (start == NULL) {
			start = newnode;
			return;
		}
		node* temp = start;
		while (temp->next != NULL)
		{
			temp = temp->next;
		}
		temp->next = newnode;
	}

	void insertnode_atbegin(int val) {
		node* newnode = new node(val);
		if (start == NULL) {
			start = newnode;
			return;
		}
		newnode->next = start;
		start = newnode;
	}

	void insertnode_atpos(int pos,int val) {
		node* newnode = new node(val);
		node* temp = start;
		for (int i = 1; i < pos-1;i++) {
			temp = temp->next;
		}
		newnode->next = temp->next;
		temp->next = newnode;
	}

	void display() {
		node* temp = start;
		while (temp != nullptr) {
			cout << temp->data << " -> ";
			temp = temp->next;
		}
		cout << "NULL" << endl;
	}

	bool search(int val) {
		node* temp = start;
		while (temp!=NULL) {
			
			
			if (temp->data == val) {
				cout << " Found!" << endl;
				return true;
			}
			temp = temp->next;
		}
		cout << "Not Found!" << endl;
		return false;
	}

	
	
};


int main()
{
	linklist li;
	li.insertnode_atbegin(12);
	li.insertnode_atend(14);
	li.insertnode_atbegin(11);
	li.insertnode_atend(15);
	li.insertnode_atpos(3, 13);
	
	li.display();
	li.search(17);
   
}
#ifndef cword_hpp
#define cword_hpp

#include <vector>
#include <string>
#include <functional>
#include <map>
#include <unordered_map>

using namespace std;

struct cword {

    int len;
    int counts[26];
    string value;

    cword() {
        len = 0;
        for(int i = 0; i < 26; ++i)
            counts[i] = 0;
    }

    cword(string s) : value(s) {
        len = 0;
        for(int i = 0; i < 26; ++i)
            counts[i] = 0;

        for(auto c : value) {
            c = tolower(c);
            if(c >= 'a' && c <= 'z') {
                counts[c-'a']++;
                len++;
            }
        }
    }

    int& operator[](const char index) {
        return counts[index-'a'];
    }

    const int& operator[](const char index) const {
        return counts[index-'a'];
    }

    bool isZero() const {
        for(int i = 0; i < 26; ++i)
            if(counts[i])
                return false;
        return true;
    }

    bool isValid() const {
        for(int i = 0; i < 26; ++i)
            if(counts[i] < 0)
                return false;
        return true;
    }

    bool isSubwordOf(const cword &o) const {
        for(char i = 'a'; i <= 'z'; ++i)
            if((*this)[i] > o[i])
                return false;
        return true;
    }
};

bool operator==(const cword &a, const cword &b) {
    for(char i = 'a'; i <= 'z'; ++i)
        if(a[i] != b[i])
            return false;
    return true;
}

bool operator<(const cword &a, const cword &b) {
    if(a.len - b.len)
        return a.len < b.len;
    for(char i = 'a'; i <= 'z'; ++i) {
        if(a[i] != b[i])
            return a[i] < b[i];
    }
    return a.value < b.value;
}

cword operator-(const cword &a, const cword &b) {
    cword ret;
    for(char i = 'a'; i <= 'z'; ++i) {
        ret[i] = a[i] - b[i];
        ret.len += ret[i];
    }
    return ret;
}

struct cword_hash {
    size_t operator()(const cword& v) const {
        size_t ret = 17;
        for(char i = 'a'; i <= 'z'; ++i)
            ret = ret * 31 + hash<int>()(v[i]);
        return ret;
    }
};

////////////////////

vector<cword> subanagram(const cword &input, const vector<cword> &dictionary) {
    vector<cword> ret;
    for(auto word : dictionary)
        if(word.isSubwordOf(input))
            ret.push_back(word);
    return ret;
}

vector<cword> subanagram(const cword &input, const vector<cword> &dictionary, const cword &until) {
    vector<cword> ret;
    for(auto word : dictionary) {
        if(!(until < word) && word.isSubwordOf(input))
            ret.push_back(word);
    }
    return ret;
}

vector<vector<cword>> _partanagram_helper(const cword &target, const vector<cword> &dictionary, const cword &until, unordered_map<cword, pair<vector<vector<cword>>, cword>, cword_hash> &grid, int limit, function<bool()> termCond) {
    vector<vector<cword>> ret;
    if(!target.isValid()) {
        return ret;
    }
    if(target.isZero()) {
        ret.push_back(vector<cword>());
        return ret;
    }

    // some memoisation
    auto g = grid.end();
    if(target.len < 10) {
        g = grid.find(target);
        if(g != grid.end()) {
            if(until < g->second.second) {
                for(auto completion : g->second.first) {
                    if(!(until < completion.back())) {
                        ret.push_back(completion);
                    }
                }
                return ret;
            }
            if (until == g->second.second) {
                return g->second.first;
            }
        }
    }

    auto subanagrams = subanagram(target, dictionary, until);
    if(target.len > 15) {
        random_shuffle(subanagrams.end() - subanagrams.size()/(target.len / 4), subanagrams.end(), arc4random_uniform);
    }
    for(int i = (int)subanagrams.size() - 1; i >= 0; --i) {
        int nextLimit = limit < 0 ? -1 : max(1, (int)(limit - ret.size()) / (i+1));
        auto completions = _partanagram_helper(target - subanagrams[i], subanagrams, subanagrams[i], grid, nextLimit, termCond);
        for(auto completion : completions) {
            completion.push_back(subanagrams[i]);
            ret.push_back(completion);
        }
        if(target.len >= 10 && (termCond() || (limit >= 0 && ret.size() > limit)))
            break;
    }

    // make a memo
    if(target.len < 10 && (g == grid.end() || g->second.second < until))
        grid[target] = pair<vector<vector<cword>>, cword>(ret, until);
    return ret;
}

vector<vector<cword>> partanagram(const cword &target, const vector<cword> &dictionary, int limit, function<bool()> termCond) {
    unordered_map<cword, pair<vector<vector<cword>>, cword>, cword_hash> grid;
    cword inf;
    inf.len = target.len + 1;
    return _partanagram_helper(target, dictionary, inf, grid, target.len > 15 ? limit : -1, termCond);
}

#endif /* cword_hpp */
